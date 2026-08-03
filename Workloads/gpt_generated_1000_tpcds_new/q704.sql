WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid_inc_tax,
        d.d_date,
        d.d_year,
        c.c_customer_id,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        ca.ca_address_id,
        ca.ca_gmt_offset,
        hd.hd_income_band_sk,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    bs.d_year,
    bs.c_customer_id,
    bs.c_birth_year,
    bs.ca_address_id,
    bs.ca_gmt_offset,
    bs.ib_upper_bound,
    bs.ss_quantity,
    bs.ss_sales_price,
    bs.ss_net_paid_inc_tax,
    cc.cc_name,
    sr.sr_return_amt,
    wr.wr_return_amt AS web_return_amt,
    ROW_NUMBER() OVER (PARTITION BY bs.c_customer_id ORDER BY bs.ss_net_paid_inc_tax DESC) AS purchase_rank,
    DENSE_RANK() OVER (ORDER BY bs.ib_upper_bound DESC) AS income_band_rank,
    u.val AS unnest_value
FROM base_sales bs
JOIN call_center cc
    ON cc.cc_closed_date_sk = bs.ss_sold_date_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = bs.ss_ticket_number
    AND sr.sr_customer_sk = bs.ss_customer_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = bs.ss_sold_date_sk
    AND wr.wr_returning_customer_sk = bs.ss_customer_sk
CROSS JOIN LATERAL (
    SELECT array[bs.ss_quantity, bs.ss_item_sk] AS qty_item_arr
) l
CROSS JOIN UNNEST(l.qty_item_arr) AS u(val)
WHERE
    bs.d_year = 2001
    AND bs.c_birth_year BETWEEN 1950 AND 1970
    AND bs.ca_gmt_offset = -5.00
    AND bs.ib_upper_bound > 50000
    AND bs.ss_net_paid_inc_tax > 1000
    AND bs.ss_net_paid_inc_tax > (
        SELECT AVG(ss2.ss_net_paid_inc_tax)
        FROM store_sales ss2
        WHERE ss2.ss_quantity = 1
    )
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = bs.ss_customer_sk
          AND sr2.sr_return_amt > 0
    )
LIMIT 100
