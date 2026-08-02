SELECT
    p.p_promo_id,
    p.p_promo_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(COALESCE(cs.cs_net_profit, 0))          AS catalog_net_profit,
    SUM(COALESCE(ss.ss_net_profit, 0))          AS store_net_profit,
    SUM(COALESCE(ws.ws_net_profit, 0))          AS web_net_profit,
    (SUM(COALESCE(cs.cs_net_profit, 0)) +
     SUM(COALESCE(ss.ss_net_profit, 0)) +
     SUM(COALESCE(ws.ws_net_profit, 0)))       AS total_net_profit,
    DENSE_RANK() OVER (
        ORDER BY (SUM(COALESCE(cs.cs_net_profit, 0)) +
                   SUM(COALESCE(ss.ss_net_profit, 0)) +
                   SUM(COALESCE(ws.ws_net_profit, 0))) DESC
    )                                           AS profit_rank
FROM promotion p
FULL OUTER JOIN store_sales ss
    ON p.p_promo_sk = ss.ss_promo_sk
   AND p.p_channel_dmail = 'Y'
LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_sales cs
    ON p.p_promo_sk = cs.cs_promo_sk
LEFT JOIN web_sales ws
    ON p.p_promo_sk = ws.ws_promo_sk
LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE (
          p.p_channel_tv = 'N'
       OR p.p_channel_tv IS NULL
      )
  AND (
          ib.ib_upper_bound < 100000
       OR ib.ib_upper_bound IS NULL
      )
  AND (
          ss.ss_quantity > 10
       OR ss.ss_quantity IS NULL
      )
GROUP BY p.p_promo_id, p.p_promo_name, ib.ib_lower_bound, ib.ib_upper_bound
HAVING (SUM(COALESCE(cs.cs_net_profit, 0)) +
        SUM(COALESCE(ss.ss_net_profit, 0)) +
        SUM(COALESCE(ws.ws_net_profit, 0))) > 1000000
ORDER BY profit_rank, total_net_profit DESC
LIMIT 100
