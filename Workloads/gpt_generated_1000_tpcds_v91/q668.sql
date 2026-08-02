WITH high_return_customers AS (
    SELECT sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND sr.sr_return_amt > 100
),
high_sales_customers AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
),
common_customers AS (
    SELECT cust_sk FROM high_return_customers
    INTERSECT
    SELECT cust_sk FROM high_sales_customers
),
joined_data AS (
    SELECT
        sr.sr_ticket_number,
        c.c_customer_id,
        d_sr.d_date AS return_date,
        d_cs.d_date AS sale_date,
        cs.cs_ext_sales_price,
        sr.sr_return_amt,
        r.r_reason_desc,
        cp.cp_type,
        cc.cc_name,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (ORDER BY sr.sr_return_amt DESC) AS rn,
        (SELECT avg(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_reason_sk = sr.sr_reason_sk) AS avg_return_amt_for_reason
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE c.c_customer_sk IN (SELECT cust_sk FROM common_customers)
      AND hd.hd_buy_potential IN ('0-500', '501-1000')
      AND d_sr.d_year = 2001
      AND d_cs.d_year = 2001
      AND r.r_reason_desc LIKE '%damaged%'
      AND cs.cs_ext_sales_price > 1000
      AND sr.sr_return_amt > 200
)
SELECT
    rn,
    sr_ticket_number,
    c_customer_id,
    return_date,
    sale_date,
    cs_ext_sales_price,
    sr_return_amt,
    avg_return_amt_for_reason,
    r_reason_desc,
    cp_type,
    cc_name,
    hd_buy_potential
FROM joined_data
ORDER BY rn
LIMIT 100
