WITH
    sales_details AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_store_sk,
            i.i_product_name,
            ss.ss_net_paid
        FROM store_sales ss
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    sales_keys AS (
        SELECT ss_ticket_number
        FROM sales_details
    ),
    returns_keys AS (
        SELECT sr.sr_ticket_number AS ss_ticket_number
        FROM store_returns sr
        JOIN date_dim d
            ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    sales_no_return_keys AS (
        SELECT ss_ticket_number FROM sales_keys
        EXCEPT
        SELECT ss_ticket_number FROM returns_keys
    ),
    sales_no_return AS (
        SELECT sd.ss_ticket_number,
               sd.ss_sold_date_sk,
               sd.ss_store_sk,
               sd.i_product_name,
               sd.ss_net_paid
        FROM sales_details sd
        JOIN sales_no_return_keys snrk
            ON sd.ss_ticket_number = snrk.ss_ticket_number
    )
SELECT
    snr.ss_ticket_number,
    snr.ss_store_sk,
    st.s_store_name,
    snr.i_product_name,
    snr.ss_net_paid,
    (SELECT COALESCE(SUM(sr.sr_return_amt), 0)
     FROM store_returns sr
     WHERE sr.sr_store_sk = snr.ss_store_sk) AS total_store_return_amt,
    (SELECT d.d_date
     FROM date_dim d
     WHERE d.d_date_sk = snr.ss_sold_date_sk) AS sale_date,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_returns r
        WHERE r.sr_ticket_number = snr.ss_ticket_number
    ) THEN 'Returned' ELSE 'No Return' END AS return_status
FROM sales_no_return snr
JOIN store st
    ON snr.ss_store_sk = st.s_store_sk
WHERE snr.ss_net_paid > (
    SELECT AVG(ss2.ss_net_paid)
    FROM store_sales ss2
    JOIN date_dim d2
        ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
ORDER BY snr.ss_net_paid DESC
LIMIT 100
