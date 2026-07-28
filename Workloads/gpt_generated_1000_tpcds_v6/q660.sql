WITH joined_data AS (
   SELECT
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       i.i_brand,
       i.i_category,
       d_sold.d_year,
       cc.cc_name,
       cc.cc_state,
       wp.wp_url,
       ws.web_name,
       cs.cs_net_profit,
       wr.wr_return_amt
   FROM catalog_sales cs
   JOIN date_dim d_sold        ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN time_dim t_sold        ON cs.cs_sold_time_sk = t_sold.t_time_sk
   JOIN customer c            ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca   ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i                ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p           ON cs.cs_promo_sk = p.p_promo_sk
   JOIN web_returns wr        ON i.i_item_sk = wr.wr_item_sk
   JOIN web_page wp           ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
   JOIN date_dim d_wp_access   ON wp.wp_access_date_sk = d_wp_access.d_date_sk
   JOIN web_site ws           ON ws.web_open_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ret        ON wr.wr_returned_date_sk = d_ret.d_date_sk
   JOIN time_dim t_ret        ON wr.wr_returned_time_sk = t_ret.t_time_sk
   WHERE d_sold.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND p.p_channel_email = 'Y'
     AND cc.cc_state = 'CA'
),
aggregated AS (
   SELECT
       c_customer_id,
       c_first_name,
       c_last_name,
       i_brand,
       i_category,
       d_year,
       cc_name,
       cc_state,
       wp_url,
       web_name,
       SUM(cs_net_profit) AS total_profit,
       SUM(wr_return_amt) AS total_returns
   FROM joined_data
   GROUP BY
       c_customer_id,
       c_first_name,
       c_last_name,
       i_brand,
       i_category,
       d_year,
       cc_name,
       cc_state,
       wp_url,
       web_name
)
SELECT
   *,
   RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year
FROM aggregated
ORDER BY profit_rank_year, total_profit DESC
LIMIT 100
