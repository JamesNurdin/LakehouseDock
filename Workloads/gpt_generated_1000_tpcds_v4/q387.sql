WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        sr.sr_return_amt,
        td.t_hour,
        c.c_birth_year,
        ca.ca_state,
        hd.hd_buy_potential,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_year = 1975
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '>10000'
      AND s.s_state = 'TX'
      AND sr.sr_return_tax > 30.00
      AND td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_tax > 50.00
      )
)
SELECT
    s_store_name,
    s_state,
    r_reason_desc,
    t_hour,
    COUNT(DISTINCT ss_ticket_number) AS transaction_cnt,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_returns,
    SUM(ss_net_profit) - SUM(sr_return_amt) AS net_profit_estimate,
    AVG(ss_quantity) AS avg_quantity
FROM base
GROUP BY s_store_name, s_state, r_reason_desc, t_hour
ORDER BY total_sales DESC
LIMIT 100
