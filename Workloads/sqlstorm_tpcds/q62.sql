WITH
store_sales_agg AS (
 SELECT
   ss.ss_sold_date_sk AS date_sk,
   ss.ss_sold_time_sk AS time_sk,
   ss.ss_item_sk AS item_sk,
   ss.ss_customer_sk AS customer_sk,
   ss.ss_store_sk AS location_sk,
   ss.ss_net_paid AS net_paid,
   ss.ss_net_profit AS net_profit,
   ss.ss_quantity AS quantity,
   ss.ss_ticket_number AS ticket_number,
   ss.ss_promo_sk AS promo_sk,
   'store' AS channel
 FROM store_sales ss
),
catalog_sales_agg AS (
 SELECT
   cs.cs_sold_date_sk AS date_sk,
   cs.cs_sold_time_sk AS time_sk,
   cs.cs_item_sk AS item_sk,
   cs.cs_bill_customer_sk AS customer_sk,
   cs.cs_call_center_sk AS location_sk,
   cs.cs_net_paid AS net_paid,
   cs.cs_net_profit AS net_profit,
   cs.cs_quantity AS quantity,
   cs.cs_order_number AS ticket_number,
   cs.cs_promo_sk AS promo_sk,
   'catalog' AS channel
 FROM catalog_sales cs
),
web_sales_agg AS (
 SELECT
   ws.ws_sold_date_sk AS date_sk,
   ws.ws_sold_time_sk AS time_sk,
   ws.ws_item_sk AS item_sk,
   ws.ws_bill_customer_sk AS customer_sk,
   ws.ws_web_page_sk AS location_sk,
   ws.ws_net_paid AS net_paid,
   ws.ws_net_profit AS net_profit,
   ws.ws_quantity AS quantity,
   ws.ws_order_number AS ticket_number,
   ws.ws_promo_sk AS promo_sk,
   'web' AS channel
 FROM web_sales ws
),
sales_union AS (
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM catalog_sales_agg
 UNION ALL
 SELECT * FROM web_sales_agg
),
store_returns_agg AS (
 SELECT
   sr.sr_returned_date_sk AS date_sk,
   sr.sr_ticket_number AS ticket_number,
   sr.sr_item_sk AS item_sk,
   sr.sr_customer_sk AS customer_sk,
   'store' AS channel,
   sr.sr_net_loss AS net_loss,
   sr.sr_return_quantity AS return_quantity
 FROM store_returns sr
),
catalog_returns_agg AS (
 SELECT
   cr.cr_returned_date_sk AS date_sk,
   cr.cr_order_number AS ticket_number,
   cr.cr_item_sk AS item_sk,
   cr.cr_returning_customer_sk AS customer_sk,
   'catalog' AS channel,
   cr.cr_net_loss AS net_loss,
   cr.cr_return_quantity AS return_quantity
 FROM catalog_returns cr
),
web_returns_agg AS (
 SELECT
   wr.wr_returned_date_sk AS date_sk,
   wr.wr_order_number AS ticket_number,
   wr.wr_item_sk AS item_sk,
   wr.wr_returning_customer_sk AS customer_sk,
   'web' AS channel,
   wr.wr_net_loss AS net_loss,
   wr.wr_return_quantity AS return_quantity
 FROM web_returns wr
),
returns_union AS (
 SELECT * FROM store_returns_agg
 UNION ALL
 SELECT * FROM catalog_returns_agg
 UNION ALL
 SELECT * FROM web_returns_agg
),
sales_with_details AS (
 SELECT
   s.channel,
   s.date_sk,
   s.time_sk,
   s.item_sk,
   s.customer_sk,
   s.location_sk,
   s.quantity,
   s.net_paid,
   s.net_profit,
   s.promo_sk,
   r.net_loss,
   d.d_date,
   d.d_year,
   t.t_hour,
   t.t_minute,
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   i.i_item_id,
   i.i_product_name,
   p.p_promo_name,
   st.s_store_id,
   st.s_store_name,
   cc.cc_call_center_id,
   cc.cc_name,
   wp.wp_web_page_id,
   wp.wp_url
 FROM sales_union s
 LEFT JOIN returns_union r
   ON s.ticket_number = r.ticket_number
   AND s.item_sk = r.item_sk
   AND s.customer_sk = r.customer_sk
   AND s.channel = r.channel
   AND s.date_sk = r.date_sk
 LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
 LEFT JOIN time_dim t ON s.time_sk = t.t_time_sk
 LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
 LEFT JOIN item i ON s.item_sk = i.i_item_sk
 LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
 LEFT JOIN store st ON s.location_sk = st.s_store_sk AND s.channel = 'store'
 LEFT JOIN call_center cc ON s.location_sk = cc.cc_call_center_sk AND s.channel = 'catalog'
 LEFT JOIN web_page wp ON s.location_sk = wp.wp_web_page_sk AND s.channel = 'web'
),
final_sales AS (
 SELECT
   swd.channel,
   swd.d_date,
   concat(lpad(cast(swd.t_hour as varchar),2,'0'),':',lpad(cast(swd.t_minute as varchar),2,'0')) AS hour_of_day,
   swd.c_customer_id,
   coalesce(swd.s_store_id, swd.cc_call_center_id, swd.wp_web_page_id) AS location_id,
   swd.i_item_id,
   swd.i_product_name,
   swd.quantity,
   swd.net_paid,
   swd.net_profit,
   CASE
     WHEN swd.net_profit IS NULL THEN NULL
     WHEN swd.net_profit > 0 THEN 'POSITIVE'
     ELSE 'NEGATIVE'
   END AS profit_flag,
   round(swd.net_profit / nullif(swd.net_paid,0),4) AS profit_margin,
   sum(swd.net_profit) over (partition by swd.channel, swd.d_date order by swd.net_profit desc rows between unbounded preceding and current row) as cumulative_profit,
   row_number() over (partition by swd.channel, swd.d_date order by swd.net_profit desc) as profit_rank,
   coalesce(swd.p_promo_name,'NONE') as promo_name,
   coalesce(swd.net_loss,0) as net_loss,
   case when coalesce(swd.net_loss,0) > 0 then 'HAS_RETURN' else 'NO_RETURN' end as return_flag,
   (select count(distinct s2.item_sk) from sales_union s2 where s2.customer_sk = swd.customer_sk and s2.date_sk < swd.date_sk) as prior_distinct_items,
   concat(swd.c_first_name,' ',swd.c_last_name) as customer_name,
   coalesce(swd.s_store_name, swd.cc_name, swd.wp_url) as location_name,
   case when swd.net_paid > 1000 then 'HIGH_VALUE' else 'NORMAL' end as value_category,
   case
     when swd.net_profit is null or swd.net_paid is null then null
     when swd.net_profit > swd.net_paid * 0.5 then 'HIGH_MARGIN'
     else 'STANDARD_MARGIN'
   end as margin_category,
   concat('Promo:',coalesce(swd.p_promo_name,''),'|Loc:',coalesce(swd.s_store_name,swd.cc_name,swd.wp_url)) as promo_location_info
 FROM sales_with_details swd
 WHERE
   (
     (swd.net_profit > 0 and swd.net_profit / nullif(swd.net_paid,0) > 0.2)
     or (swd.net_profit is null and swd.net_paid > 500)
     or (swd.net_loss > 0)
   )
   and (swd.d_year = 2001 or swd.d_year is null)
),
ranked_sales AS (
 SELECT *
 FROM final_sales
 WHERE profit_rank <= 10
)
SELECT *
FROM ranked_sales
ORDER BY channel, d_date, profit_rank
