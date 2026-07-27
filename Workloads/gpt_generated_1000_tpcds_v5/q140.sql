WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid)                AS total_cs_net_paid,
        COUNT(*)                           AS cs_order_cnt,
        MAX(cs.cs_ext_discount_amt)        AS max_cs_discount,
        MIN(cs.cs_ext_discount_amt)        AS min_cs_discount,
        MIN(cs.cs_sold_date_sk)            AS first_sale_date_sk
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE ib.ib_upper_bound > 50000
      AND p.p_channel_dmail = 'Y'
      AND cs.cs_quantity > 5
    GROUP BY cs.cs_bill_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    p.p_promo_id,
    cs_agg.total_cs_net_paid,
    ws.ws_net_paid,
    ws.ws_order_number,
    RANK() OVER (
        PARTITION BY ib.ib_income_band_sk
        ORDER BY (cs_agg.total_cs_net_paid + ws.ws_net_paid) DESC
    ) AS income_band_rank,
    CASE
        WHEN ws.ws_net_paid > cs_agg.total_cs_net_paid THEN 'Web Higher'
        ELSE 'Catalog Higher'
    END AS higher_channel
FROM cs_agg
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = cs_agg.customer_sk
JOIN customer c
    ON c.c_customer_sk = cs_agg.customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
WHERE ws.ws_quantity > 3
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_id = p.p_promo_id
          AND p2.p_discount_active = 'Y'
    )
ORDER BY income_band_rank
LIMIT 100
