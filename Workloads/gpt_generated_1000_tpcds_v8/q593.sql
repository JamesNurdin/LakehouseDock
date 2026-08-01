WITH sampled_sales AS (
    SELECT ws_sold_date_sk,
           ws_sold_time_sk,
           ws_ship_date_sk,
           ws_item_sk,
           ws_bill_customer_sk,
           ws_ship_customer_sk,
           ws_web_page_sk,
           ws_quantity,
           ws_ext_sales_price,
           ws_net_profit,
           ws_order_number,
           ws_ext_discount_amt,
           ws_ext_wholesale_cost,
           ws_ext_tax
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_ext_sales_price > 1000
      AND ws_quantity >= 1
      AND ws_ext_discount_amt < 500
      AND ws_order_number > 1000
      AND ws_ext_wholesale_cost IS NOT NULL
),
joined AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_preferred_cust_flag,
           t.t_hour,
           t.t_shift,
           t.t_sub_shift,
           wp.wp_type,
           wp.wp_url,
           wp.wp_rec_start_date,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_order_number
    FROM sampled_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND t.t_sub_shift = 'morning'
      AND wp.wp_type = 'content'
),
agg1 AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           t_hour,
           t_shift,
           wp_type,
           SUM(ws_ext_sales_price)   AS total_sales,
           SUM(ws_net_profit)        AS total_profit,
           COUNT(*)                  AS sale_cnt
    FROM joined
    GROUP BY GROUPING SETS (
        (c_customer_sk, c_first_name, c_last_name, t_hour, t_shift, wp_type),
        (c_customer_sk, c_first_name, c_last_name),
        (t_hour, t_shift, wp_type),
        ()
    )
),
agg2 AS (
    SELECT c_customer_sk,
           CAST(NULL AS varchar)    AS c_first_name,
           CAST(NULL AS varchar)    AS c_last_name,
           t_hour,
           CAST(NULL AS varchar)    AS t_shift,
           CAST(NULL AS varchar)    AS wp_type,
           SUM(ws_ext_sales_price)   AS total_sales,
           SUM(ws_net_profit)        AS total_profit,
           COUNT(*)                  AS sale_cnt
    FROM joined
    GROUP BY GROUPING SETS (
        (c_customer_sk, t_hour),
        ()
    )
),
union_agg AS (
    SELECT * FROM agg1
    UNION
    SELECT * FROM agg2
),
full_join AS (
    SELECT a.c_customer_sk,
           a.c_first_name,
           a.c_last_name,
           a.total_sales,
           a.total_profit,
           b.wp_url,
           b.wp_rec_start_date
    FROM union_agg a
    FULL OUTER JOIN (
        SELECT DISTINCT wp.wp_customer_sk AS c_customer_sk,
                        wp.wp_url,
                        wp.wp_rec_start_date
        FROM web_page wp
        WHERE wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
          AND wp.wp_type = 'content'
    ) b
    ON a.c_customer_sk = b.c_customer_sk
),
customer_in_sales AS (
    SELECT DISTINCT ws_bill_customer_sk AS c_customer_sk
    FROM web_sales
),
customer_in_page AS (
    SELECT DISTINCT wp_customer_sk AS c_customer_sk
    FROM web_page
),
customer_exclusive AS (
    SELECT c_customer_sk FROM customer_in_sales
    EXCEPT
    SELECT c_customer_sk FROM customer_in_page
),
final AS (
    SELECT fj.c_customer_sk,
           fj.c_first_name,
           fj.c_last_name,
           fj.total_sales,
           fj.total_profit,
           fj.wp_url,
           fj.wp_rec_start_date,
           (
               SELECT AVG(ua.total_sales)
               FROM union_agg ua
               WHERE ua.c_customer_sk = fj.c_customer_sk
           ) AS avg_sales_per_customer
    FROM full_join fj
    WHERE fj.total_sales IS NOT NULL
      AND fj.c_customer_sk IN (SELECT c_customer_sk FROM customer_exclusive)
)
SELECT c_customer_sk,
       c_first_name,
       c_last_name,
       total_sales,
       total_profit,
       wp_url,
       wp_rec_start_date,
       avg_sales_per_customer
FROM final
ORDER BY total_sales DESC
LIMIT 100
