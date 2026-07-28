WITH cat_agg AS (
    SELECT
        cs_sold_date_sk,
        SUM(cs_ext_sales_price) AS cat_sales_amount,
        SUM(cs_net_profit) AS cat_total_profit,
        COUNT(*) AS cat_txn_cnt
    FROM catalog_sales
    WHERE cs_ext_tax > 50           -- predicate inside CTE
    GROUP BY cs_sold_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    cat_agg.cat_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (cat_agg.cat_total_profit + SUM(ws.ws_net_profit)) AS combined_profit,
    (SELECT AVG(cs_net_paid_inc_ship_tax) FROM catalog_sales) AS overall_avg_paid_inc_ship_tax
FROM cat_agg
JOIN date_dim d
    ON cat_agg.cs_sold_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001                                 -- predicate 1
  AND d.d_holiday = 'N'                               -- predicate 2
  AND ws.ws_warehouse_sk IN (4, 16, 20)               -- predicate 3
  AND d.d_dom BETWEEN 10 AND 20
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    cat_agg.cat_sales_amount,
    cat_agg.cat_total_profit
HAVING (cat_agg.cat_total_profit + SUM(ws.ws_net_profit)) > (
        SELECT AVG(cs_net_paid_inc_ship_tax) FROM catalog_sales
    )
ORDER BY d.d_date DESC
LIMIT 100
