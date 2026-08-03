WITH cs AS (
   SELECT cs.cs_order_number,
          cs.cs_sold_date_sk,
          cs.cs_item_sk,
          cs.cs_bill_customer_sk,
          cs.cs_bill_hdemo_sk,
          cs.cs_bill_addr_sk,
          cs.cs_promo_sk,
          cs.cs_net_profit,
          cs.cs_quantity
   FROM catalog_sales cs
   TABLESAMPLE BERNOULLI (10) -- sample 10% of catalog_sales
   WHERE cs.cs_quantity > 1
),
store_combined AS (
   SELECT ss.ss_sold_date_sk,
          ss.ss_item_sk,
          ss.ss_customer_sk,
          ss.ss_hdemo_sk,
          ss.ss_addr_sk,
          ss.ss_promo_sk,
          ss.ss_ticket_number,
          ss.ss_net_profit        AS ss_net_profit,
          sr.sr_return_amt        AS sr_return_amt,
          wr.wr_return_amt        AS wr_return_amt
   FROM store_sales ss
   FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk      = sr.sr_item_sk
   LEFT JOIN web_returns wr
        ON ss.ss_item_sk      = wr.wr_item_sk
       AND ss.ss_customer_sk  = wr.wr_refunded_customer_sk
),
joined AS (
SELECT
    c.c_customer_id,
    i.i_item_id,
    d1.d_year,
    SUM(cs.cs_net_profit) OVER (PARTITION BY c.c_customer_id, d1.d_year) AS yearly_profit,
    CAST(hd.hd_income_band_sk AS VARCHAR) AS income_band,
    w.web_name,
    COALESCE(ssc.ss_net_profit, 0) - COALESCE(ssc.sr_return_amt, 0) - COALESCE(ssc.wr_return_amt, 0) AS adjusted_profit
FROM cs
JOIN date_dim d1               ON cs.cs_sold_date_sk   = d1.d_date_sk
JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca       ON cs.cs_bill_addr_sk   = ca.ca_address_sk
JOIN item i                    ON cs.cs_item_sk        = i.i_item_sk
JOIN promotion p               ON cs.cs_promo_sk       = p.p_promo_sk
JOIN date_dim d_promo_start    ON p.p_start_date_sk    = d_promo_start.d_date_sk
JOIN web_site w                ON d_promo_start.d_date_sk = w.web_open_date_sk
LEFT JOIN store_combined ssc   ON cs.cs_item_sk = ssc.ss_item_sk
                               AND cs.cs_bill_customer_sk = ssc.ss_customer_sk
WHERE d1.d_year BETWEEN 2000 AND 2002
  AND ca.ca_state = 'CA'
  AND i.i_category = 'Electronics'
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count > 0
)
SELECT DISTINCT
    c_customer_id,
    i_item_id,
    d_year,
    yearly_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY yearly_profit DESC) AS profit_rank,
    income_band,
    web_name,
    adjusted_profit
FROM joined
ORDER BY profit_rank, c_customer_id
LIMIT 100
