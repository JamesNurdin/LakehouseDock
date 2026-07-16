WITH 
sales AS (
    SELECT 
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_ext_sales_price AS sales_price,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_net_profit AS profit,
        cs.cs_bill_customer_sk AS customer_sk,
        ca.ca_state AS state
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        ss.ss_customer_sk,
        st.s_state AS state
    FROM store_sales ss
    JOIN store st
      ON ss.ss_store_sk = st.s_store_sk

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        ca2.ca_state AS state
    FROM web_sales ws
    JOIN customer_address ca2
      ON ws.ws_bill_addr_sk = ca2.ca_address_sk
),
returns AS (
    SELECT 
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_amount AS return_amount,
        ca.ca_state AS state
    FROM catalog_returns cr
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_amt,
        st2.s_state AS state
    FROM store_returns sr
    JOIN store st2
      ON sr.sr_store_sk = st2.s_store_sk

    UNION ALL

    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_amt,
        ca3.ca_state AS state
    FROM web_returns wr
    JOIN customer_address ca3
      ON wr.wr_refunded_addr_sk = ca3.ca_address_sk
),
item_lookup AS (
    SELECT i_item_sk, i_item_id
    FROM item
),
item_rank AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        s.state,
        s.item_sk,
        SUM(s.profit) AS item_profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq, s.state ORDER BY SUM(s.profit) DESC) AS rank
    FROM sales s
    JOIN date_dim d
      ON s.sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, s.state, s.item_sk
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        s.state,
        SUM(s.sales_price) AS total_sales,
        SUM(s.profit) AS total_profit,
        SUM(s.discount_amt) AS total_discount,
        COUNT(DISTINCT s.customer_sk) AS customer_cnt
    FROM sales s
    JOIN date_dim d
      ON s.sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, s.state
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        r.state,
        SUM(r.return_amount) AS total_returns
    FROM returns r
    JOIN date_dim d
      ON r.returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, r.state
)
SELECT
    sa.d_year,
    sa.month,
    sa.state,
    sa.total_sales,
    sa.total_profit,
    MAX(COALESCE(ra.total_returns, 0)) AS total_returns,
    CASE WHEN sa.customer_cnt = 0 THEN 0 ELSE sa.total_profit / sa.customer_cnt END AS profit_per_customer,
    CASE WHEN sa.total_sales = 0 THEN 0 ELSE sa.total_discount / sa.total_sales END AS avg_discount_pct,
    MAX(CASE WHEN ir.rank = 1 THEN il.i_item_id END) AS top_item_1_id,
    MAX(CASE WHEN ir.rank = 1 THEN ir.item_profit END) AS top_item_1_profit,
    MAX(CASE WHEN ir.rank = 2 THEN il.i_item_id END) AS top_item_2_id,
    MAX(CASE WHEN ir.rank = 2 THEN ir.item_profit END) AS top_item_2_profit,
    MAX(CASE WHEN ir.rank = 3 THEN il.i_item_id END) AS top_item_3_id,
    MAX(CASE WHEN ir.rank = 3 THEN ir.item_profit END) AS top_item_3_profit
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.d_year = ra.d_year AND sa.month = ra.month AND sa.state = ra.state
LEFT JOIN item_rank ir
  ON sa.d_year = ir.d_year AND sa.month = ir.month AND sa.state = ir.state
LEFT JOIN item_lookup il
  ON ir.item_sk = il.i_item_sk
GROUP BY
    sa.d_year,
    sa.month,
    sa.state,
    sa.total_sales,
    sa.total_profit,
    sa.customer_cnt,
    sa.total_discount
ORDER BY
    sa.d_year,
    sa.month,
    sa.state
