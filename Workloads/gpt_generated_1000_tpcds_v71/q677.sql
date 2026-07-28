WITH sales_agg AS (
    SELECT
        d_sold.d_year AS year,
        cp.cp_department AS department,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_quantity) AS avg_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2002
      AND cs.cs_quantity > 2
      AND cs.cs_net_profit > 0
      AND cp.cp_department IN ('Books', 'Electronics')
      AND t_sold.t_hour BETWEEN 8 AND 20
    GROUP BY d_sold.d_year, cp.cp_department
),
returns_agg AS (
    SELECT
        d_ret.d_year AS year,
        r.r_reason_desc AS reason,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
        ON wr.wr_returned_time_sk = t_ret.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_year = 2001
      AND wr.wr_return_amt > 50
      AND r.r_reason_desc LIKE '%warranty%'
    GROUP BY d_ret.d_year, r.r_reason_desc
),
inventory_agg AS (
    SELECT
        d_inv.d_year AS year,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
      AND inv.inv_quantity_on_hand > 0
    GROUP BY d_inv.d_year
),
website_agg AS (
    SELECT
        d_ws_open.d_year AS year,
        ws.web_name,
        ws.web_country,
        COUNT(*) AS site_cnt
    FROM web_site ws
    JOIN date_dim d_ws_open
        ON ws.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_ws_open.d_year = 2001
      AND ws.web_country = 'United States'
    GROUP BY d_ws_open.d_year, ws.web_name, ws.web_country
),
combined AS (
    SELECT
        s.year,
        s.department,
        s.total_net_paid,
        s.total_profit,
        s.sales_cnt,
        s.avg_qty,
        r.reason,
        r.total_return_amount,
        r.return_cnt
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.year = r.year
    WHERE s.total_profit > 1000
),
final_combined AS (
    SELECT
        c.*,
        i.total_on_hand,
        w.site_cnt,
        w.web_name
    FROM combined c
    LEFT JOIN inventory_agg i
        ON c.year = i.year
    LEFT JOIN website_agg w
        ON c.year = w.year
)
SELECT
    f.year,
    f.department,
    f.total_net_paid,
    f.total_profit,
    f.sales_cnt,
    f.avg_qty,
    f.reason,
    f.total_return_amount,
    f.return_cnt,
    ROW_NUMBER() OVER (PARTITION BY f.year ORDER BY f.total_profit DESC) AS profit_rank,
    (SELECT COUNT(*) FROM sales_agg sa WHERE sa.year = f.year) AS dept_count_per_year
FROM final_combined f
WHERE f.sales_cnt > 10
  AND (f.total_return_amount IS NULL OR f.total_return_amount < 5000)
ORDER BY f.year, profit_rank
LIMIT 100
