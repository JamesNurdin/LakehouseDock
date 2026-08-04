WITH catalog AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450845               -- roughly a month range
      AND cs.cs_ext_sales_price > 500                                  -- filter on sales amount
),
promo_expanded AS (
    SELECT
        c.cs_order_number,
        p.p_promo_sk,
        p.p_discount_active,
        ARRAY[p.p_promo_sk] AS promo_ids
    FROM catalog c
    JOIN promotion p ON c.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'                                    -- only active promotions
),
promo_unnest AS (
    SELECT
        ce.cs_order_number,
        u.promo_id
    FROM catalog ce
    JOIN promo_expanded pe ON ce.cs_order_number = pe.cs_order_number
    CROSS JOIN UNNEST(pe.promo_ids) AS u(promo_id)                     -- expand the one‑element array
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    SUM(ss.ss_net_profit)                     AS total_store_profit,
    AVG(ws.ws_net_paid)                       AS avg_web_paid,
    COUNT(DISTINCT cat.cs_order_number)       AS distinct_catalog_orders,
    SUM(pu.promo_id)                          AS sum_promo_ids,
    MIN(t.t_hour)                             AS min_sold_hour,
    MAX(ib.ib_upper_bound)                    AS max_income_upper
FROM catalog cat
JOIN time_dim t ON cat.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cat.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cat.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cat.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p ON cat.cs_promo_sk = p.p_promo_sk
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk               -- uses customer_address
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promo_unnest pu ON pu.cs_order_number = cat.cs_order_number
WHERE cd.cd_gender = 'F'                                 -- female customers only
  AND ib.ib_lower_bound >= 50001                         -- middle‑income band
  AND s.s_state = 'CA'                                   -- stores located in California
  AND wp.wp_type = 'home'                                -- web pages of type 'home'
  AND EXISTS (                                            -- at least one matching web_page for the customer
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'home'
      )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name
ORDER BY total_store_profit DESC
LIMIT 100
