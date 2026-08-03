WITH filtered_items AS (
   SELECT DISTINCT i_item_sk
   FROM item
   WHERE i_brand = 'Brand#12'
),
base_sales AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ca.ca_state,
      st.s_store_id,
      st.s_store_name,
      st.s_state,
      hd.hd_buy_potential,
      tm.t_hour,
      p.p_discount_active,
      inv.inv_quantity_on_hand
   FROM store_sales ss
   JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
   JOIN time_dim tm            ON ss.ss_sold_time_sk = tm.t_time_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca    ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store st               ON ss.ss_store_sk = st.s_store_sk
   JOIN promotion p            ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN inventory inv     ON ss.ss_item_sk = inv.inv_item_sk
   WHERE
      tm.t_hour BETWEEN 9 AND 11
      AND st.s_state = 'CA'
      AND hd.hd_buy_potential = '5001-10000'
      AND p.p_discount_active = 'Y'
      AND ss.ss_quantity > 2
      AND EXISTS (
         SELECT 1
         FROM catalog_sales cs
         JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
         WHERE cs.cs_item_sk = ss.ss_item_sk
           AND sm.sm_contract = 'OrDuVy2H'
      )
),
return_sales AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ca.ca_state,
      st.s_store_id,
      st.s_store_name,
      st.s_state,
      hd.hd_buy_potential,
      tm.t_hour,
      p.p_discount_active,
      inv.inv_quantity_on_hand,
      sr.sr_return_amt
   FROM store_sales ss
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN time_dim tm            ON ss.ss_sold_time_sk = tm.t_time_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca    ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store st               ON ss.ss_store_sk = st.s_store_sk
   JOIN promotion p            ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN inventory inv     ON ss.ss_item_sk = inv.inv_item_sk
   WHERE
      tm.t_hour BETWEEN 9 AND 11
      AND st.s_state = 'CA'
      AND hd.hd_buy_potential = '5001-10000'
      AND p.p_discount_active = 'Y'
      AND ss.ss_quantity > 2
)
SELECT
   store_id,
   store_name,
   total_net_paid,
   avg_quantity,
   distinct_tickets,
   min_profit,
   max_inventory,
   ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_net_paid DESC) AS state_sales_rank
FROM (
   SELECT
      st.s_store_id   AS store_id,
      st.s_store_name AS store_name,
      st.s_state      AS state,
      SUM(ss.ss_net_paid)            AS total_net_paid,
      AVG(ss.ss_quantity)            AS avg_quantity,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
      MIN(ss.ss_net_profit)          AS min_profit,
      MAX(inv.inv_quantity_on_hand)  AS max_inventory
   FROM base_sales ss
   JOIN store st   ON ss.ss_store_sk = st.s_store_sk
   LEFT JOIN inventory inv ON ss.ss_item_sk = inv.inv_item_sk
   GROUP BY st.s_store_id, st.s_store_name, st.s_state

   UNION DISTINCT

   SELECT
      st.s_store_id   AS store_id,
      st.s_store_name AS store_name,
      st.s_state      AS state,
      SUM(rs.sr_return_amt)          AS total_net_paid,
      AVG(rs.ss_quantity)            AS avg_quantity,
      COUNT(DISTINCT rs.ss_ticket_number) AS distinct_tickets,
      MIN(rs.ss_net_profit)          AS min_profit,
      MAX(inv.inv_quantity_on_hand)  AS max_inventory
   FROM return_sales rs
   JOIN store st   ON rs.ss_store_sk = st.s_store_sk
   LEFT JOIN inventory inv ON rs.ss_item_sk = inv.inv_item_sk
   GROUP BY st.s_store_id, st.s_store_name, st.s_state
) agg
ORDER BY total_net_paid DESC
LIMIT 100
