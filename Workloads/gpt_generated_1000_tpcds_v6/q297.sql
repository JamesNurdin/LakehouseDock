WITH
/* stores that are either in Texas or in a city starting with 'Buena' */
eligible_stores AS (
    SELECT s_store_sk FROM store WHERE s_state = 'TX'
    UNION
    SELECT s_store_sk FROM store WHERE s_city LIKE 'Buena%'
),
/* inventory aggregated per item/date */
inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
),
/* the big join that brings together all 14 tables */
base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk   AS s_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        d.d_year,
        t.t_hour,
        i.i_brand,
        i.i_item_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        s.s_store_name,
        s.s_state,
        s.s_city,
        p.p_discount_active,
        inv.total_on_hand,
        sr.sr_return_amt,
        cr.cr_return_amount,
        wr.wr_return_amt,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inv_agg inv              ON inv.inv_item_sk = ss.ss_item_sk
                                   AND inv.inv_date_sk = ss.ss_sold_date_sk
    LEFT JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_returns cr  ON cr.cr_returned_date_sk = d.d_date_sk
                                   AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_returns wr      ON wr.wr_returned_date_sk = d.d_date_sk
                                   AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN income_band ib      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND hd.hd_buy_potential = '5000-10000'
      AND EXISTS (SELECT 1 FROM eligible_stores es WHERE es.s_store_sk = s.s_store_sk)
      AND EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk AND p2.p_discount_active = 'Y')
),
/* aggregate profit and returns per store per year */
agg AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        d_year,
        SUM(ss_net_profit)               AS total_profit,
        SUM(ss_sales_price)              AS total_sales,
        SUM(COALESCE(sr_return_amt,0))   AS total_store_return,
        SUM(COALESCE(cr_return_amount,0)) AS total_catalog_return,
        SUM(COALESCE(wr_return_amt,0))   AS total_web_return,
        SUM(COALESCE(total_on_hand,0))   AS total_on_hand
    FROM base
    GROUP BY s_store_sk, s_store_name, s_city, d_year
)
SELECT DISTINCT
    a.s_store_name,
    a.s_city,
    a.d_year,
    a.total_profit,
    a.total_sales,
    a.total_store_return,
    a.total_catalog_return,
    a.total_web_return,
    a.total_on_hand,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank,
    (SELECT AVG(ss_sales_price) FROM base b2 WHERE b2.s_store_sk = a.s_store_sk) AS avg_store_item_price,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_store_sk = a.s_store_sk) AS store_return_transactions
FROM agg a
WHERE a.total_profit > 10000
ORDER BY a.d_year, profit_rank
LIMIT 100
