WITH base AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       p.p_promo_name,
       r.r_reason_desc,
       td.t_hour,
       ss.ss_net_profit,
       sr.sr_return_amt,
       cs.cs_net_profit,
       wr.wr_return_amt,
       ss.ss_list_price,
       sr.sr_return_tax,
       wp.wp_autogen_flag,
       p.p_discount_active,
       i.i_rec_start_date
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                         AND cs.cs_sold_time_sk = td.t_time_sk
                         AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
                         AND cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                        AND wr.wr_returned_time_sk = td.t_time_sk
                        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
                        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND i.i_category = 'Electronics'
     AND ss.ss_list_price > 50
     AND sr.sr_return_tax < 10
     AND wp.wp_autogen_flag = 'N'
     AND p.p_discount_active = 'Y'
     AND i.i_rec_start_date > DATE '2000-01-01'
)
SELECT
    i_item_id,
    i_product_name,
    p_promo_name,
    AVG(total_profit) AS avg_total_profit,
    SUM(total_return_amt) AS sum_total_return_amt
FROM (
    SELECT
        i_item_id,
        i_product_name,
        p_promo_name,
        SUM(ss_net_profit) + SUM(cs_net_profit) AS total_profit,
        SUM(sr_return_amt) + SUM(wr_return_amt) AS total_return_amt
    FROM base
    GROUP BY i_item_id, i_product_name, p_promo_name
) agg
GROUP BY i_item_id, i_product_name, p_promo_name
HAVING AVG(total_profit) > 100
ORDER BY avg_total_profit DESC
LIMIT 20
