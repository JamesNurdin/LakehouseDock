WITH cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND cs.cs_sold_date_sk IN (
          SELECT d_date_sk
          FROM date_dim
          WHERE d_fy_year = 1913
            AND d_fy_week_seq = 17
      )
)
SELECT
    d.d_year,
    i.i_category,
    hd.hd_buy_potential,
    ws.ws_order_number,
    ws.ws_net_paid,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MAX(ws.ws_net_paid) AS max_web_paid
FROM cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE d.d_fy_year = 1913
  AND i.i_color = 'purple'
  AND w.web_company_name = 'anti'
GROUP BY d.d_year, i.i_category, hd.hd_buy_potential, ws.ws_order_number, ws.ws_net_paid
ORDER BY total_sales DESC
LIMIT 100
