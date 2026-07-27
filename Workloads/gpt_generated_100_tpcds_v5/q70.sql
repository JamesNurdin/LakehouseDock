WITH distinct_customers AS (
    SELECT DISTINCT c.c_customer_sk, cd.cd_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
agg AS (
    SELECT
        i.i_category,
        d_sold.d_year,
        COUNT(DISTINCT cs.cs_order_number)               AS orders,
        SUM(cs.cs_ext_sales_price)                       AS catalog_sales,
        SUM(ws.ws_ext_sales_price)                       AS web_sales,
        SUM(cs.cs_net_profit + ws.ws_net_profit)         AS total_profit,
        SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS positive_profit,
        CASE WHEN SUM(cs.cs_net_profit + ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        COUNT(DISTINCT c_bill.c_customer_sk)             AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN distinct_customers c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN distinct_customers c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d_sold.d_year = 2001
    GROUP BY i.i_category, d_sold.d_year
)
SELECT
    a.i_category,
    a.d_year,
    a.orders,
    a.catalog_sales,
    a.web_sales,
    a.total_profit,
    a.positive_profit,
    a.profit_flag,
    a.distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 100
