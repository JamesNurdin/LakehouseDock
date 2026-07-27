WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS total_profit
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        regexp_like(i.i_item_desc, '(?i)steel')
        AND d.d_year = 2002
    GROUP BY
        cs.cs_bill_customer_sk,
        cs.cs_item_sk
),
returns_agg AS (
    SELECT
        wr.wr_returning_customer_sk AS cust_sk,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM
        web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2002
    GROUP BY
        wr.wr_returning_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_email_address,
    regexp_extract(c.c_email_address, '([^@]+)@', 1) AS email_user,
    s.total_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    s.total_profit - COALESCE(r.total_return_amt, 0) AS net_contribution
FROM
    sales_agg s
    JOIN customer c ON s.cust_sk = c.c_customer_sk
    LEFT JOIN returns_agg r ON s.cust_sk = r.cust_sk
WHERE
    c.c_email_address LIKE '%@gmail.com'
ORDER BY
    net_contribution DESC
LIMIT 100
