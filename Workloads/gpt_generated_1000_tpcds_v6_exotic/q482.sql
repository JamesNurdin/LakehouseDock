WITH cs_agg AS (
    SELECT
        cs_sold_date_sk,
        cs_catalog_page_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_ext_sales_price > 1000
      AND cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY cs_sold_date_sk, cs_catalog_page_sk
)
SELECT
    d.d_year,
    c.c_customer_id,
    cc.cc_name,
    cp.cp_department,
    ws.ws_order_number,
    ss.ss_ticket_number,
    cs_agg.total_sales,
    cs_agg.total_profit,
    SUM(ws.ws_net_paid) AS ws_net_paid_total,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    CASE
        WHEN cs_agg.total_profit / NULLIF(cs_agg.total_sales, 0) > 0.2 THEN 'High Margin'
        ELSE 'Low Margin'
    END AS profit_category,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND EXISTS (
              SELECT 1
              FROM reason r_sub
              WHERE r_sub.r_reason_sk = wr.wr_reason_sk
                AND r_sub.r_reason_desc LIKE '%damaged%'
          )
    ) AS damaged_return_cnt
FROM cs_agg
JOIN catalog_page cp
  ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d
  ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site we
  ON we.web_open_date_sk = d.d_date_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d.d_date_sk
JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND c.c_birth_month = 5
  AND cc.cc_name = 'Call Center 1'
  AND cp.cp_department = 'Electronics'
  AND inv.inv_quantity_on_hand > 500
  AND r.r_reason_desc LIKE '%damaged%'
  AND ws.ws_quantity > 5
GROUP BY
    d.d_year,
    c.c_customer_id,
    cc.cc_name,
    cp.cp_department,
    ws.ws_order_number,
    ss.ss_ticket_number,
    cs_agg.total_sales,
    cs_agg.total_profit,
    CASE
        WHEN cs_agg.total_profit / NULLIF(cs_agg.total_sales, 0) > 0.2 THEN 'High Margin'
        ELSE 'Low Margin'
    END
ORDER BY d.d_year DESC, cs_agg.total_sales DESC
LIMIT 100
