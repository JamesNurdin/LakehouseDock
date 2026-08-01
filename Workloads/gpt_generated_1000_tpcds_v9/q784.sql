WITH sales_agg AS (
    SELECT
        cp.cp_department,
        d.d_year,
        d.d_month_seq,
        d.d_date_sk AS sold_date_sk,
        cs.cs_bill_customer_sk AS bill_customer_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_number BETWEEN 5 AND 20
      AND d.d_year = 2022
      AND cs.cs_quantity > 0
    GROUP BY cp.cp_department, d.d_year, d.d_month_seq, d.d_date_sk, cs.cs_bill_customer_sk
    HAVING SUM(cs.cs_quantity) > 100
),
returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk
),
dept_agg AS (
    SELECT
        s.cp_department,
        s.d_year,
        s.d_month_seq,
        SUM(s.total_net_profit) AS dept_total_net_profit,
        SUM(s.total_quantity) AS dept_total_quantity,
        SUM(COALESCE(r.total_return_amt, 0)) AS dept_total_return_amt,
        SUM(s.total_net_profit) - SUM(COALESCE(r.total_return_amt, 0)) AS dept_net_profit_adj,
        MAX(inv.qty_on_hand) AS qty_on_hand
    FROM sales_agg s
    LEFT JOIN returns_agg r ON s.bill_customer_sk = r.customer_sk
    LEFT JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS qty_on_hand
        FROM inventory inv
        WHERE inv.inv_date_sk = s.sold_date_sk
    ) AS inv ON TRUE
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = s.bill_customer_sk
          AND wr2.wr_return_amt > 10
    )
    GROUP BY s.cp_department, s.d_year, s.d_month_seq
    HAVING SUM(s.total_net_profit) > 5000
)
SELECT
    d.cp_department,
    d.d_year,
    d.d_month_seq,
    d.dept_total_net_profit,
    d.dept_total_quantity,
    d.dept_total_return_amt,
    d.dept_net_profit_adj,
    d.qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY d.cp_department ORDER BY d.dept_total_net_profit DESC) AS profit_rank
FROM dept_agg d
ORDER BY d.dept_total_net_profit DESC
LIMIT 100
