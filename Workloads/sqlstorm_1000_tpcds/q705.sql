WITH
 store_sales_agg AS (
   SELECT
     ss.ss_customer_sk AS customer_sk,
     CAST(NULL AS integer) AS call_center_sk,
     CAST(NULL AS integer) AS web_page_sk,
     ss.ss_store_sk AS store_sk,
     ss.ss_sold_date_sk AS date_sk,
     d.d_year,
     i.i_brand,
     i.i_category,
     i.i_product_name,
     CAST(ss.ss_quantity AS double) AS quantity,
     ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
     ss.ss_net_profit AS net_profit,
     ss.ss_ext_discount_amt AS discount_amt,
     CASE WHEN ss.ss_net_paid_inc_tax > 0 THEN ss.ss_net_profit / ss.ss_net_paid_inc_tax ELSE NULL END AS profit_margin
   FROM store_sales ss
   LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
 ),
 catalog_sales_agg AS (
   SELECT
     cs.cs_bill_customer_sk AS customer_sk,
     cs.cs_call_center_sk AS call_center_sk,
     CAST(NULL AS integer) AS web_page_sk,
     CAST(NULL AS integer) AS store_sk,
     cs.cs_sold_date_sk AS date_sk,
     d.d_year,
     i.i_brand,
     i.i_category,
     i.i_product_name,
     CAST(cs.cs_quantity AS double) AS quantity,
     cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
     cs.cs_net_profit AS net_profit,
     cs.cs_ext_discount_amt AS discount_amt,
     CASE WHEN cs.cs_net_paid_inc_tax > 0 THEN cs.cs_net_profit / cs.cs_net_paid_inc_tax ELSE NULL END AS profit_margin
   FROM catalog_sales cs
   LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 ),
 web_sales_agg AS (
   SELECT
     ws.ws_bill_customer_sk AS customer_sk,
     CAST(NULL AS integer) AS call_center_sk,
     ws.ws_web_page_sk AS web_page_sk,
     CAST(NULL AS integer) AS store_sk,
     ws.ws_sold_date_sk AS date_sk,
     d.d_year,
     i.i_brand,
     i.i_category,
     i.i_product_name,
     CAST(ws.ws_quantity AS double) AS quantity,
     ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
     ws.ws_net_profit AS net_profit,
     ws.ws_ext_discount_amt AS discount_amt,
     CASE WHEN ws.ws_net_paid_inc_tax > 0 THEN ws.ws_net_profit / ws.ws_net_paid_inc_tax ELSE NULL END AS profit_margin
   FROM web_sales ws
   LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
 ),
 all_sales AS (
   SELECT * FROM store_sales_agg
   UNION ALL
   SELECT * FROM catalog_sales_agg
   UNION ALL
   SELECT * FROM web_sales_agg
 ),
 customer_yearly AS (
   SELECT
     customer_sk,
     d_year,
     SUM(net_paid_inc_tax) AS total_net_paid,
     SUM(net_profit) AS total_profit,
     SUM(quantity) AS total_quantity,
     SUM(discount_amt) AS total_discount,
     AVG(profit_margin) AS avg_profit_margin
   FROM all_sales
   GROUP BY customer_sk, d_year
 ),
 ranked_customers AS (
   SELECT
     cy.customer_sk,
     cy.d_year,
     cy.total_net_paid,
     cy.total_profit,
     cy.total_quantity,
     cy.total_discount,
     cy.avg_profit_margin,
     ROW_NUMBER() OVER (PARTITION BY cy.d_year ORDER BY cy.total_profit DESC) AS profit_rank,
     (SELECT COALESCE(prev.total_profit, 0)
        FROM customer_yearly prev
       WHERE prev.customer_sk = cy.customer_sk AND prev.d_year = cy.d_year - 1) AS prev_year_profit,
     CASE
        WHEN (SELECT COALESCE(prev.total_profit, 0)
                FROM customer_yearly prev
               WHERE prev.customer_sk = cy.customer_sk AND prev.d_year = cy.d_year - 1) = 0 THEN NULL
        ELSE ((cy.total_profit - (SELECT COALESCE(prev.total_profit, 0)
                                   FROM customer_yearly prev
                                  WHERE prev.customer_sk = cy.customer_sk AND prev.d_year = cy.d_year - 1))
              / (SELECT COALESCE(prev.total_profit, 0)
                 FROM customer_yearly prev
                WHERE prev.customer_sk = cy.customer_sk AND prev.d_year = cy.d_year - 1))
     END AS profit_growth_ratio
   FROM customer_yearly cy
 ),
 final_result AS (
   SELECT
     rc.d_year,
     rc.profit_rank,
     rc.total_profit,
     rc.total_net_paid,
     rc.total_quantity,
     rc.avg_profit_margin,
     rc.profit_growth_ratio,
     concat(COALESCE(c.c_first_name, 'UNKNOWN'), ' ', COALESCE(c.c_last_name, 'UNKNOWN')) AS customer_full_name,
     c.c_preferred_cust_flag,
     cd.cd_gender,
     cd.cd_marital_status,
     hd.hd_buy_potential,
     COALESCE(cc.cc_name, 'NO_CALL_CENTER') AS call_center_name,
     CASE WHEN rc.profit_rank <= 5 THEN 'TOP5' ELSE 'OTHER' END AS tier,
     CASE WHEN ca.ca_address_id IS NOT NULL THEN concat_ws(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) ELSE NULL END AS customer_address,
     (COALESCE(rc.total_net_paid, 0) - COALESCE(rc.total_discount, 0)) AS net_after_discount
   FROM ranked_customers rc
   LEFT JOIN customer c ON rc.customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN call_center cc ON rc.customer_sk = cc.cc_call_center_sk
   WHERE rc.profit_rank <= 10
 )
SELECT *
FROM final_result
ORDER BY d_year DESC, profit_rank
