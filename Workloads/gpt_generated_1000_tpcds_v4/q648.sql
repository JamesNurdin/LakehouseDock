WITH agg_returns AS (
    SELECT
        sr_returned_date_sk,
        sr_addr_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2452500 AND 2453000
      AND sr_return_amt > 0
      AND sr_return_quantity >= 1
    GROUP BY sr_returned_date_sk, sr_addr_sk
)
SELECT
    ca_ret.ca_state,
    sm.sm_type,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(ar.total_return_amt) AS total_returns,
    (SUM(cs.cs_net_paid) - SUM(ar.total_return_amt)) / NULLIF(SUM(cs.cs_net_paid), 0) AS profit_margin
FROM agg_returns ar
JOIN date_dim d_ret
    ON ar.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca_ret
    ON ar.sr_addr_sk = ca_ret.ca_address_sk
JOIN catalog_sales cs
    ON cs.cs_bill_addr_sk = ca_ret.ca_address_sk
   AND cs.cs_sold_date_sk = d_ret.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON wp.wp_access_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2002
  AND ca_ret.ca_state = 'CA'
  AND cs.cs_quantity > 1
  AND cs.cs_sales_price > 100
  AND sm.sm_type = 'AIR'
  AND wp.wp_autogen_flag = 'N'
  AND p.p_discount_active = 'Y'
  AND wp.wp_max_ad_count >= 2
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_channel_email = 'Y'
    )
GROUP BY ca_ret.ca_state, sm.sm_type
ORDER BY profit_margin DESC
LIMIT 100
