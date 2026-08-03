WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_date_sk,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM inventory
   GROUP BY inv_item_sk, inv_date_sk
),
base AS (
   SELECT
       d.d_date,
       d.d_year,
       c_refund.c_customer_id,
       SUM(cr.cr_return_amount) AS cat_return_amt,
       SUM(sr.sr_return_amt) AS store_return_amt,
       SUM(wr.wr_return_amt) AS web_return_amt,
       SUM(cr.cr_return_amount) + SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amt
   FROM date_dim d
   JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN store_returns sr   ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN web_returns wr    ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN inv_agg i          ON i.inv_date_sk = d.d_date_sk
   JOIN promotion p        ON p.p_start_date_sk = d.d_date_sk
   JOIN web_page wp        ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN customer c_refund ON c_refund.c_customer_sk = cr.cr_refunded_customer_sk
   JOIN customer_demographics cd_refund ON cd_refund.cd_demo_sk = cr.cr_refunded_cdemo_sk
   JOIN customer_address ca_refund ON ca_refund.ca_address_sk = cr.cr_refunded_addr_sk
   JOIN customer c_return ON c_return.c_customer_sk = cr.cr_returning_customer_sk
   JOIN customer_demographics cd_return ON cd_return.cd_demo_sk = cr.cr_returning_cdemo_sk
   JOIN customer_address ca_return ON ca_return.ca_address_sk = cr.cr_returning_addr_sk
   JOIN customer c_store ON c_store.c_customer_sk = sr.sr_customer_sk
   JOIN customer_demographics cd_store ON cd_store.cd_demo_sk = sr.sr_cdemo_sk
   JOIN customer_address ca_store ON ca_store.ca_address_sk = sr.sr_addr_sk
   JOIN customer c_wr_refund ON c_wr_refund.c_customer_sk = wr.wr_refunded_customer_sk
   JOIN customer_demographics cd_wr_refund ON cd_wr_refund.cd_demo_sk = wr.wr_refunded_cdemo_sk
   JOIN customer_address ca_wr_refund ON ca_wr_refund.ca_address_sk = wr.wr_refunded_addr_sk
   JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
   WHERE d.d_year = 2000
     AND d.d_month_seq BETWEEN 1200 AND 1300
     AND cr.cr_return_amount > 100
     AND sr.sr_net_loss > 0
     AND wp.wp_link_count >= 10
     AND p.p_discount_active = 'Y'
   GROUP BY d.d_date, d.d_year, c_refund.c_customer_id
)
SELECT
    b.d_date,
    b.c_customer_id,
    b.cat_return_amt,
    b.store_return_amt,
    b.web_return_amt,
    b.total_return_amt,
    CASE WHEN b.total_return_amt > 500 THEN 'High' ELSE 'Low' END AS return_category,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.total_return_amt DESC) AS yearly_rank
FROM base b
ORDER BY yearly_rank, b.total_return_amt DESC
LIMIT 100
