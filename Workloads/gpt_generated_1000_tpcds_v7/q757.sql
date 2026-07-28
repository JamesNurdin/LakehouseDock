WITH sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        d.d_year,
        i.i_category,
        i.i_product_name,
        i.i_current_price,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ca.ca_state
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
)
SELECT
    s.d_year,
    s.i_category,
    s.i_product_name,
    s.ca_state,
    s.cd_gender,
    s.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    s.ss_quantity,
    s.ss_net_paid,
    sr.sr_return_quantity,
    sr.sr_return_amt_inc_tax,
    inv.inv_quantity_on_hand,
    ws.ws_quantity AS web_quantity,
    ws.ws_net_paid AS web_net_paid,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.ss_net_paid DESC) AS sales_rank,
    SUM(s.ss_net_paid) OVER (PARTITION BY s.d_year) AS yearly_sales_total
FROM sales s
JOIN store_returns sr
    ON sr.sr_ticket_number = s.ss_ticket_number
    AND sr.sr_item_sk = s.ss_item_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN inventory inv
    ON inv.inv_item_sk = s.ss_item_sk
    AND inv.inv_date_sk = s.ss_sold_date_sk
JOIN income_band ib
    ON s.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_item_sk = s.ss_item_sk
    AND ws.ws_sold_date_sk = s.ss_sold_date_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = s.ss_item_sk
WHERE s.d_year = 2001
  AND s.i_current_price > 50
  AND s.ca_state = 'TX'
  AND s.cd_gender = 'M'
  AND ib.ib_lower_bound >= 50000
  AND s.ss_quantity >= 2
ORDER BY s.d_year, sales_rank
LIMIT 10
