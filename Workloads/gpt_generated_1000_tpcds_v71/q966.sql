WITH
  sales_detail AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_customer_sk,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      p.p_promo_id,
      d_sales.d_year,
      CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_group
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d_sales.d_year = 2001
  ),
  returns_union AS (
    SELECT
      sr.sr_customer_sk   AS cust_sk,
      sr.sr_returned_date_sk AS ret_date_sk,
      sr.sr_net_loss      AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT
      wr.wr_refunded_customer_sk AS cust_sk,
      wr.wr_returned_date_sk    AS ret_date_sk,
      wr.wr_net_loss            AS net_loss
    FROM web_returns wr
  )
SELECT
  agg.c_customer_id,
  agg.ca_city,
  agg.cd_gender,
  agg.hd_vehicle_count,
  agg.ib_lower_bound,
  agg.total_sales,
  agg.total_returns_loss,
  agg.qty_group_cnt,
  CASE WHEN agg.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM (
  SELECT
    c.c_customer_id,
    ca_current.ca_city,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    SUM(sd.ss_net_paid)                     AS total_sales,
    SUM(COALESCE(ru.net_loss, 0))            AS total_returns_loss,
    COUNT(DISTINCT sd.qty_group)             AS qty_group_cnt,
    SUM(sd.ss_net_profit)                    AS total_profit
  FROM sales_detail sd
  JOIN customer c ON sd.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca_current ON c.c_current_addr_sk = ca_current.ca_address_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN inventory inv ON inv.inv_date_sk = sd.ss_sold_date_sk
  JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
  LEFT JOIN returns_union ru ON ru.cust_sk = c.c_customer_sk
  WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_customer_sk = c.c_customer_sk
      AND r.r_reason_desc = 'Damaged'
  )
  GROUP BY
    c.c_customer_id,
    ca_current.ca_city,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_lower_bound
) agg
ORDER BY agg.total_sales DESC
LIMIT 100
