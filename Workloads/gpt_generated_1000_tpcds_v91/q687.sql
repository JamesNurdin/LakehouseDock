WITH inv_agg AS (
   SELECT inv_item_sk,
          SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   GROUP BY inv_item_sk
),
joined_all AS (
   SELECT
      cc.cc_call_center_id,
      cs.cs_order_number,
      c.c_customer_id,
      ca.ca_city,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      i.i_item_id,
      i.i_brand,
      i.i_color,
      p.p_promo_name,
      p.p_discount_active,
      s.s_store_id,
      s.s_state,
      d.d_date,
      d.d_year,
      d.d_month_seq,
      ws.ws_order_number,
      ss.ss_ticket_number,
      inv_agg.total_qty_on_hand,
      cs.cs_net_profit,
      ss.ss_net_profit,
      ws.ws_net_profit
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
   JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                        AND ss.ss_sold_date_sk = d.d_date_sk
                        AND ss.ss_customer_sk = c.c_customer_sk
                        AND ss.ss_cdemo_sk = cd.cd_demo_sk
                        AND ss.ss_hdemo_sk = hd.hd_demo_sk
                        AND ss.ss_addr_sk = ca.ca_address_sk
                        AND ss.ss_promo_sk = p.p_promo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
                AND s.s_closed_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                        AND ws.ws_sold_date_sk = d.d_date_sk
                        AND ws.ws_bill_customer_sk = c.c_customer_sk
                        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                        AND ws.ws_bill_addr_sk = ca.ca_address_sk
                        AND ws.ws_promo_sk = p.p_promo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
                        AND wp.wp_access_date_sk = d.d_date_sk
                        AND wp.wp_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
     AND c.c_preferred_cust_flag = 'Y'
     AND i.i_color = 'BLUE'
     AND p.p_discount_active = 'Y'
     AND s.s_state = 'CA'
),
profit_base AS (
   SELECT
      c_customer_id,
      total_qty_on_hand,
      (cs_net_profit + ss_net_profit + ws_net_profit) AS total_profit,
      d_year,
      i_brand,
      i_color,
      s_state,
      p_promo_name
   FROM joined_all
),
positive AS (
   SELECT * FROM profit_base WHERE total_profit > 0
),
negative AS (
   SELECT * FROM profit_base WHERE total_profit <= 0
),
combined AS (
   SELECT * FROM positive
   UNION ALL
   SELECT * FROM negative
),
exclude AS (
   SELECT * FROM profit_base WHERE total_profit < 10
),
final_set AS (
   SELECT * FROM combined
   EXCEPT
   SELECT * FROM exclude
)
SELECT
   c_customer_id,
   total_qty_on_hand,
   total_profit,
   d_year,
   i_brand,
   i_color,
   s_state,
   p_promo_name,
   RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM final_set
ORDER BY profit_rank
LIMIT 100
