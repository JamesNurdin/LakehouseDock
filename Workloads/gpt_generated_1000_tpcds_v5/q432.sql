WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM date_dim d
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cs.cs_wholesale_cost > 30
      AND cd.cd_gender = 'F'
      AND w.w_street_name LIKE '%Broadway%'
      AND s.s_state = 'TX'
      AND ws.ws_quantity >= 5
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    s_store_id,
    d_year,
    catalog_net_profit,
    web_net_profit,
    total_sales,
    catalog_orders,
    web_orders,
    (catalog_net_profit + web_net_profit) AS combined_profit,
    RANK() OVER (ORDER BY (catalog_net_profit + web_net_profit) DESC) AS profit_rank,
    CASE
        WHEN (catalog_net_profit + web_net_profit) > 100000 THEN 'High'
        WHEN (catalog_net_profit + web_net_profit) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
