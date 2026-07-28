WITH sr AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_fee
    FROM store_returns sr
)
SELECT
    d.d_year,
    i.i_brand,
    i.i_brand_id,
    s.s_state,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_fee) AS avg_fee,
    SUM(inv.inv_quantity_on_hand) AS total_inventory
FROM sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND i.i_brand_id = 10008011
    AND s.s_state = 'CA'
GROUP BY
    d.d_year,
    i.i_brand,
    i.i_brand_id,
    s.s_state
LIMIT 100
