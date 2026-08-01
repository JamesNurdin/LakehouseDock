WITH call_center_sample AS (
    SELECT *
    FROM tpcds.call_center
    TABLESAMPLE BERNOULLI (10)
    WHERE cc_country = 'United States'
),
store_sales_agg AS (
    SELECT ss_store_sk,
           ss_sold_date_sk,
           SUM(ss_net_profit) AS total_store_profit,
           SUM(ss_quantity)    AS total_quantity
    FROM tpcds.store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_store_sk, ss_sold_date_sk
)
SELECT
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    p.p_promo_name,
    dp.p_promo_name            AS distinct_promo_in_set,
    w.w_warehouse_name,
    hd.hd_buy_potential,
    ss_agg.total_store_profit,
    ws.ws_sales_price,
    ws.ws_ext_tax,
    wr.wr_net_loss,
    ret.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY ss_agg.total_store_profit DESC) AS warehouse_profit_rank,
    RANK()        OVER (ORDER BY ws.ws_sales_price DESC)                     AS sales_price_rank
FROM call_center_sample cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_sales_agg ss_agg
    ON ss_agg.ss_store_sk   = ss.ss_store_sk
   AND ss_agg.ss_sold_date_sk = ss.ss_sold_date_sk
JOIN promotion p
    ON p.p_promo_sk = ss.ss_promo_sk
JOIN web_sales ws
    ON ws.ws_promo_sk       = p.p_promo_sk
   AND ws.ws_warehouse_sk   = w.w_warehouse_sk
   AND ws.ws_bill_hdemo_sk  = hd.hd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS return_cnt
    FROM tpcds.web_returns wr2
    WHERE wr2.wr_order_number = ws.ws_order_number
) ret ON true
/* Cross‑join with a small computed set and a distinct promo list */
CROSS JOIN (SELECT DATE '2023-01-01' AS analysis_date) AS dt
CROSS JOIN (SELECT DISTINCT p2.p_promo_name FROM tpcds.promotion p2) AS dp
WHERE ws.ws_ext_tax > 30
  AND ws.ws_sales_price BETWEEN 20 AND 200
  AND cc.cc_state = 'CA'
GROUP BY ROLLUP(
    w.w_warehouse_name,
    p.p_promo_name,
    dp.p_promo_name,
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    hd.hd_buy_potential,
    ss_agg.total_store_profit,
    ws.ws_sales_price,
    ws.ws_ext_tax,
    wr.wr_net_loss,
    ret.return_cnt,
    dt.analysis_date
)
ORDER BY warehouse_profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
