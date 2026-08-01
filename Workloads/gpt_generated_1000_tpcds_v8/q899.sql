WITH distinct_items AS (
   SELECT DISTINCT i_item_sk,
                   i_item_id,
                   i_product_name,
                   i_item_desc
   FROM   item
   WHERE  i_brand = 'Brand#12'
),
sales_agg AS (
   SELECT
       di.i_item_sk,
       di.i_item_id,
       di.i_product_name,
       d.d_year,
       SUM(ss.ss_net_paid)                AS store_net_paid,
       SUM(ws.ws_net_paid)                AS web_net_paid,
       SUM(inv.inv_quantity_on_hand)      AS total_inventory,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
       COUNT(DISTINCT w)                  AS distinct_word_count
   FROM
       (SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)) ss
   JOIN date_dim d
         ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN distinct_items di
         ON ss.ss_item_sk = di.i_item_sk
   JOIN customer c
         ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
         ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN inventory inv
         ON inv.inv_item_sk = di.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
   JOIN web_sales ws
         ON ws.ws_item_sk = di.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c_bill
         ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN customer_demographics cd2
         ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
   LEFT JOIN UNNEST(split(di.i_item_desc, ' ')) AS t(w) ON true
   WHERE
       d.d_year BETWEEN 2000 AND 2002
       AND inv.inv_quantity_on_hand > 0
       AND ss.ss_net_paid > 100
       AND cd.cd_gender = 'M'
       AND EXISTS (
           SELECT 1
           FROM   customer c_pref
           WHERE  c_pref.c_customer_sk = ss.ss_customer_sk
                 AND c_pref.c_preferred_cust_flag = 'Y'
       )
   GROUP BY
       di.i_item_sk,
       di.i_item_id,
       di.i_product_name,
       d.d_year
),
ranked AS (
   SELECT
       ROW_NUMBER() OVER (ORDER BY (store_net_paid + web_net_paid) DESC) AS row_num,
       i_item_id,
       i_product_name,
       d_year,
       store_net_paid,
       web_net_paid,
       total_inventory,
       distinct_tickets,
       distinct_word_count,
       (store_net_paid + web_net_paid)                               AS total_sales
   FROM   sales_agg
   WHERE  (store_net_paid + web_net_paid) > (
              SELECT AVG(store_net_paid + web_net_paid) FROM sales_agg)
)
SELECT
   row_num,
   i_item_id,
   i_product_name,
   d_year,
   store_net_paid,
   web_net_paid,
   total_inventory,
   distinct_tickets,
   distinct_word_count,
   total_sales
FROM   ranked
WHERE  row_num <= 100
ORDER BY total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
