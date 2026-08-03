WITH joined_all AS (
    SELECT
        t.t_time_sk,
        t.t_hour,
        s.s_store_sk,
        s.s_store_id,
        s.s_state AS store_state,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_county,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        p.p_promo_sk,
        p.p_promo_name,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_upper_bound,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_item_sk,
        cs.cs_quantity,
        cc.cc_call_center_sk,
        cc.cc_state AS cc_state,
        sm.sm_ship_mode_sk,
        ws.ws_quantity,
        wr.wr_return_amt
    FROM time_dim t
    JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE ca.ca_state = 'CA'
      AND cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_promo_name LIKE '%Clearance%'
      AND t.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound > 50000
),
aggregated AS (
    SELECT
        ja.s_store_sk,
        ja.s_store_id,
        ja.store_state,
        ja.i_category,
        ja.i_brand,
        SUM(ja.ss_net_paid) AS total_net_paid,
        SUM(ja.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt,
        ROW_NUMBER() OVER (PARTITION BY ja.s_store_id ORDER BY SUM(ja.ss_net_profit) DESC) AS profit_rank
    FROM joined_all ja
    GROUP BY GROUPING SETS (
        (ja.s_store_sk, ja.s_store_id, ja.store_state, ja.i_category, ja.i_brand),
        (ja.s_store_sk, ja.s_store_id, ja.store_state),
        ()
    )
),
high_profit AS (
    SELECT s_store_sk FROM aggregated WHERE total_profit > 200000
),
top_rank AS (
    SELECT s_store_sk FROM aggregated WHERE profit_rank = 1
),
except_set AS (
    SELECT s_store_sk FROM high_profit
    EXCEPT
    SELECT s_store_sk FROM top_rank
),
high_paid AS (
    SELECT s_store_sk FROM aggregated WHERE total_net_paid > 150000
),
category_elec AS (
    SELECT s_store_sk FROM aggregated WHERE i_category = 'Electronics'
),
intersect_set AS (
    SELECT s_store_sk FROM high_paid
    INTERSECT
    SELECT s_store_sk FROM category_elec
),
overall_total AS (
    SELECT SUM(ss_net_paid) AS overall_net_paid FROM joined_all
),
hour_dim AS (
    SELECT DISTINCT t_hour FROM time_dim WHERE t_hour BETWEEN 9 AND 10
),
cross_join_set AS (
    SELECT h.t_hour, ot.overall_net_paid
    FROM hour_dim h CROSS JOIN overall_total ot
)
SELECT
    a.s_store_id,
    a.store_state,
    a.i_category,
    a.i_brand,
    a.total_net_paid,
    a.total_profit,
    a.txn_cnt,
    a.profit_rank,
    CASE WHEN a.s_store_sk IN (SELECT s_store_sk FROM except_set) THEN 1 ELSE 0 END AS in_except,
    CASE WHEN a.s_store_sk IN (SELECT s_store_sk FROM intersect_set) THEN 1 ELSE 0 END AS in_intersect,
    cjs.t_hour,
    cjs.overall_net_paid
FROM aggregated a
CROSS JOIN cross_join_set cjs
WHERE a.s_store_sk IS NOT NULL
ORDER BY a.total_profit DESC, a.s_store_id
LIMIT 100
