SELECT
    c.c_customer_id,
    ca.ca_state,
    p.p_promo_name,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    SUM(ss.ss_ext_sales_price) OVER (PARTITION BY c.c_customer_id) AS cust_total_sales,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY ss.ss_net_profit DESC) AS profit_state_rank,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_ext_sales_price DESC) AS promo_sales_rank
FROM
    store_sales ss
INNER JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
INNER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
INNER JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
WHERE
    ss.ss_ext_sales_price > 1000
    AND p.p_discount_active = 'Y'
    AND ib.ib_upper_bound >= 100000
    AND ca.ca_state = 'TX'
    AND td.t_hour BETWEEN 9 AND 17
    AND c.c_preferred_cust_flag = 'Y'
    AND hd.hd_buy_potential = '>10000'
    AND sr.sr_net_loss > 0
LIMIT 100
