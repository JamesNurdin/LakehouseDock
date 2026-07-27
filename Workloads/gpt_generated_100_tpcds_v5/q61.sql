WITH
  sales_base AS (
    SELECT
      cs.cs_net_paid,
      cs.cs_net_profit,
      d_sold.d_year,
      hd_bill.hd_buy_potential,
      ca_bill.ca_state
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  ),
  sales_agg AS (
    SELECT
      d_year,
      hd_buy_potential,
      ca_state,
      SUM(cs_net_paid)   AS total_sales,
      SUM(cs_net_profit) AS total_profit
    FROM sales_base
    GROUP BY d_year, hd_buy_potential, ca_state
  ),
  returns_base AS (
    SELECT
      sr.sr_net_loss,
      d_ret.d_year,
      hd_ret.hd_buy_potential,
      ca_ret.ca_state
    FROM store_returns sr
    JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_ret
      ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret
      ON sr.sr_addr_sk = ca_ret.ca_address_sk
  ),
  returns_agg AS (
    SELECT
      d_year,
      hd_buy_potential,
      ca_state,
      SUM(sr_net_loss) AS total_return_loss
    FROM returns_base
    GROUP BY d_year, hd_buy_potential, ca_state
  )
SELECT
  s.d_year,
  s.hd_buy_potential,
  s.ca_state,
  s.total_sales,
  s.total_profit,
  r.total_return_loss
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
  AND s.hd_buy_potential = r.hd_buy_potential
  AND s.ca_state = r.ca_state
ORDER BY s.d_year DESC, s.total_sales DESC
LIMIT 100
