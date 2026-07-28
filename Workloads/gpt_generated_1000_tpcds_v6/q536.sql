WITH agg AS (
    SELECT
        d.d_date,
        s.s_store_name,
        ws.web_name,
        t.t_hour,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(wr.wr_return_amt) AS total_web_returns,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM date_dim d
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON t.t_time_sk = cs.cs_sold_time_sk
    WHERE d.d_fy_year = 1917
      AND inv.inv_item_sk IN (101444, 101419)
      AND s.s_number_employees >= 100
      AND cs.cs_net_paid > 5000
      AND wr.wr_return_amt > 200
    GROUP BY d.d_date, s.s_store_name, ws.web_name, t.t_hour
)
SELECT
    d_date,
    s_store_name,
    web_name,
    t_hour,
    total_sales,
    total_profit,
    total_catalog_returns,
    total_store_returns,
    total_web_returns,
    avg_inventory,
    distinct_customers,
    SUM(total_sales) OVER (PARTITION BY s_store_name ORDER BY d_date ROWS UNBOUNDED PRECEDING) AS running_sales
FROM agg
ORDER BY total_sales DESC
LIMIT 100
