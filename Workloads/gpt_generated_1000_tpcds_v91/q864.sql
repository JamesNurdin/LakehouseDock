WITH online_customers AS (
    SELECT DISTINCT c.c_customer_id,
                    c.c_first_name,
                    c.c_last_name
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_start_date < DATE '2002-01-01'
),
store_customers AS (
    SELECT DISTINCT c.c_customer_id,
                    c.c_first_name,
                    c.c_last_name
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_start_date < DATE '2002-01-01'
),
online_spend AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_paid) AS total_online_spent
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_start_date < DATE '2002-01-01'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
online_only AS (
    SELECT oc.c_customer_id,
           oc.c_first_name,
           oc.c_last_name
    FROM online_customers oc
    EXCEPT
    SELECT sc.c_customer_id,
           sc.c_first_name,
           sc.c_last_name
    FROM store_customers sc
)
SELECT oo.c_customer_id,
       oo.c_first_name,
       oo.c_last_name,
       os.total_online_spent
FROM online_only oo
JOIN online_spend os
  ON oo.c_customer_id = os.c_customer_id
 AND oo.c_first_name = os.c_first_name
 AND oo.c_last_name = os.c_last_name
ORDER BY os.total_online_spent DESC
LIMIT 100
