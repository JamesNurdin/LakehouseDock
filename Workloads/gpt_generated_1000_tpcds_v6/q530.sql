WITH
    -- Join store sales with its customer and time dimension
    ss_cust AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_item_sk,
            ss.ss_customer_sk,
            ss.ss_ticket_number,
            ss.ss_net_paid,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            t.t_hour AS sales_hour
        FROM store_sales ss
        JOIN customer c
          ON ss.ss_customer_sk = c.c_customer_sk
        JOIN time_dim t
          ON ss.ss_sold_time_sk = t.t_time_sk
    ),
    -- Join store returns (ticket side) to sales and its return‑time dimension
    sr_ticket AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_return_time_sk,
            t.t_time_sk AS return_time_sk
        FROM store_returns sr
        JOIN time_dim t
          ON sr.sr_return_time_sk = t.t_time_sk
    ),
    -- Join store returns (item side) to sales and to the returning customer
    sr_item AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_customer_sk,
            sr.sr_net_loss
        FROM store_returns sr
        JOIN customer c2
          ON sr.sr_customer_sk = c2.c_customer_sk
    ),
    -- Join web returns to its time dimension and both customer roles
    wr_full AS (
        SELECT
            wr.wr_returned_time_sk,
            wr.wr_refunded_customer_sk,
            wr.wr_returning_customer_sk,
            wr.wr_net_loss,
            t.t_time_sk AS wr_time_sk,
            cr.c_customer_id   AS refunded_cust_id,
            cr.c_first_name    AS refunded_first_name,
            cr.c_last_name     AS refunded_last_name,
            cr2.c_customer_id  AS returning_cust_id,
            cr2.c_first_name   AS returning_first_name,
            cr2.c_last_name    AS returning_last_name
        FROM web_returns wr
        JOIN time_dim t
          ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN customer cr
          ON wr.wr_refunded_customer_sk = cr.c_customer_sk
        JOIN customer cr2
          ON wr.wr_returning_customer_sk = cr2.c_customer_sk
    )
SELECT
    sc.c_customer_id,
    sc.c_first_name,
    sc.c_last_name,
    sc.sales_hour,
    SUM(sc.ss_net_paid)                         AS total_sales_net_paid,
    SUM(si.sr_net_loss)                         AS total_store_returns_net_loss,
    SUM(wr.wr_net_loss)                         AS total_web_returns_net_loss
FROM ss_cust sc
JOIN store_sales ss
  ON sc.ss_ticket_number = ss.ss_ticket_number
JOIN sr_ticket st
  ON sc.ss_ticket_number = st.sr_ticket_number
JOIN sr_item si
  ON sc.ss_item_sk = si.sr_item_sk
JOIN wr_full wr
  ON sc.ss_customer_sk = wr.wr_returning_customer_sk
GROUP BY
    sc.c_customer_id,
    sc.c_first_name,
    sc.c_last_name,
    sc.sales_hour
ORDER BY total_sales_net_paid DESC
LIMIT 100
