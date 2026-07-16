WITH sales_agg AS (
    SELECT cp.cp_department AS department,
           ca.ca_state AS state,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           AVG(cs.cs_ext_discount_amt) AS avg_discount,
           SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_end_date_sk = 2450996
    GROUP BY cp.cp_department, ca.ca_state
),
returns_agg AS (
    SELECT ca.ca_state AS state,
           SUM(wr.wr_return_amt) AS total_return_amount,
           SUM(wr.wr_net_loss) AS total_net_loss,
           COUNT(*) AS return_count
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY ca.ca_state
)
SELECT s.department,
       s.state,
       s.total_net_profit,
       s.total_sales,
       s.avg_discount,
       s.total_quantity,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       COALESCE(r.total_net_loss, 0) AS total_net_loss,
       COALESCE(r.return_count, 0) AS return_count,
       RANK() OVER (PARTITION BY s.state ORDER BY s.total_net_profit DESC) AS profit_rank_by_state
FROM sales_agg s
LEFT JOIN returns_agg r ON s.state = r.state
WHERE s.total_net_profit > 0
ORDER BY s.state, profit_rank_by_state
LIMIT 50
