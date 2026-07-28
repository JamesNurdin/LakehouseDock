WITH recent_dates AS (
    SELECT d_date_sk,
           d_date,
           d_month_seq,
           d_year
    FROM tpcds.date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    'catalog' AS channel,
    i.i_item_id AS item_id,
    rd.d_month_seq AS month_seq,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit
FROM tpcds.catalog_sales cs
JOIN recent_dates rd
  ON cs.cs_sold_date_sk = rd.d_date_sk
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_ext_sales_price > (
        SELECT AVG(p.p_cost)
        FROM tpcds.promotion p
        WHERE p.p_item_sk = i.i_item_sk
    )
GROUP BY i.i_item_id, rd.d_month_seq

UNION ALL

SELECT
    'store' AS channel,
    i.i_item_id AS item_id,
    rd.d_month_seq AS month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit
FROM tpcds.store_sales ss
JOIN recent_dates rd
  ON ss.ss_sold_date_sk = rd.d_date_sk
JOIN tpcds.item i
  ON ss.ss_item_sk = i.i_item_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY i.i_item_id, rd.d_month_seq

ORDER BY channel,
         month_seq,
         total_sales DESC
LIMIT 100
