WITH joined AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_birth_country,
    ca.ca_zip,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    sr.sr_net_loss,
    ws.ws_net_profit,
    ws.ws_sold_date_sk,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_web_site_sk,
    web_site.web_name,
    web_site.web_rec_start_date
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
  WHERE c.c_birth_country = 'SWITZERLAND'
    AND c.c_first_name = 'Rose'
    AND ca.ca_zip = '86192'
    AND ib.ib_lower_bound >= 30000
    AND r.r_reason_desc LIKE '%damaged%'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
    AND web_site.web_rec_start_date > DATE '2000-01-01'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_quantity > 1
    )
),
agg AS (
  SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    AVG(ws_ext_sales_price) AS avg_sales_price
  FROM joined
  GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
)
SELECT
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  total_net_loss,
  total_net_profit,
  distinct_customers,
  avg_sales_price,
  total_net_profit / NULLIF(total_net_loss, 0) AS profit_to_loss_ratio
FROM agg
WHERE distinct_customers >= 5
  AND total_net_profit > 0
ORDER BY profit_to_loss_ratio DESC NULLS LAST
LIMIT 100
