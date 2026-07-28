-- goal: Identify the top‑performing items in 2001 for California stores, accounting for sales, returns, inventory and promotions, and rank them by total profit.
WITH filtered_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year = 2001                     -- filter predicate 1
),
item_filtered AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_category, i_brand
    FROM item
    WHERE i_category = 'Books'               -- filter predicate 2
      AND i_brand = 'Brand#1'
),
promo_filtered AS (
    SELECT p_promo_sk, p_promo_id, p_channel_tv, p_discount_active
    FROM promotion
    WHERE p_channel_tv = 'Y'                -- filter predicate 3
      AND p_discount_active = 'Y'
),
store_filtered AS (
    SELECT s_store_sk, s_store_name, s_state
    FROM store
    WHERE s_state = 'CA'
),
call_center_filtered AS (
    SELECT cc_call_center_sk, cc_name
    FROM call_center
    WHERE cc_market_manager = 'John Doe'
),
joined_all AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_item_desc,
        s.s_store_name,
        c.c_customer_id,
        cd.cd_gender,
        p.p_promo_id,
        cc.cc_name,
        cr.cr_net_loss,
        ss.ss_net_profit,
        ws.ws_net_profit,
        inv.inv_quantity_on_hand,
        rc.r_reason_desc
    FROM store_sales ss
    JOIN filtered_dates d              ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item_filtered i               ON ss.ss_item_sk = i.i_item_sk
    JOIN store_filtered s              ON ss.ss_store_sk = s.s_store_sk
    JOIN promo_filtered p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c                     ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr      ON cr.cr_item_sk = i.i_item_sk
                                      AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason rc               ON cr.cr_reason_sk = rc.r_reason_sk
    LEFT JOIN inventory inv           ON inv.inv_item_sk = i.i_item_sk
                                      AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center_filtered cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_sales ws            ON ws.ws_item_sk = i.i_item_sk
                                      AND ws.ws_sold_date_sk = d.d_date_sk
),
aggregated AS (
    SELECT
        d_year,
        i_item_id,
        i_item_desc,
        SUM(ss_net_profit + ws_net_profit) AS total_profit,
        SUM(cr_net_loss) AS total_return_loss,
        AVG(inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT s_store_name) AS store_count
    FROM joined_all
    GROUP BY d_year, i_item_id, i_item_desc
)
SELECT
    a.d_year,
    a.i_item_id,
    a.i_item_desc,
    a.total_profit,
    a.total_return_loss,
    a.avg_inventory,
    a.store_count,
    CASE
        WHEN a.total_profit > (
            SELECT AVG(item_profit)
            FROM (
                SELECT DISTINCT i_item_id, SUM(ss_net_profit + ws_net_profit) AS item_profit
                FROM joined_all
                GROUP BY i_item_id
            ) sub
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank
FROM aggregated a
WHERE a.d_year = 2001
ORDER BY a.total_profit DESC
LIMIT 100
