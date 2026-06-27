WITH combined AS (
    -- Store sales (positive profit)
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ca.ca_state,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'

    UNION ALL

    -- Catalog sales (positive profit)
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ca.ca_state,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'

    UNION ALL

    -- Catalog returns (negative profit = loss)
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ca.ca_state,
           -cr.cr_net_loss AS profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
)
SELECT d_year,
       d_month_seq,
       i_category,
       ca_state,
       SUM(profit) AS total_profit
FROM combined
GROUP BY d_year, d_month_seq, i_category, ca_state
ORDER BY d_year, d_month_seq, i_category, ca_state
