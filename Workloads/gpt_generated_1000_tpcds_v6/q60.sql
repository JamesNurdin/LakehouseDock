WITH web_ret_agg AS (
    SELECT
        wr_item_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr_return_amt) AS web_return_amt,
        AVG(wr_return_tax) AS web_avg_tax,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY SUM(wr_return_amt) DESC) AS rn_item
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 0
      AND wr_return_tax BETWEEN 0.5 AND 50
      AND wr_returned_date_sk BETWEEN 2450000 AND 2455000
      AND wr_reason_sk IN (1, 2, 3)
    GROUP BY wr_item_sk
    HAVING SUM(wr_return_amt) > 100
)
SELECT
    i.i_brand,
    i.i_category,
    s.s_store_name,
    ca.ca_state,
    hd.hd_buy_potential,
    COUNT(sr.sr_ticket_number) AS store_return_cnt,
    SUM(sr.sr_return_amt) AS store_return_total,
    AVG(sr.sr_return_tax) AS store_avg_tax,
    SUM(COALESCE(wra.web_return_amt, 0)) AS web_return_total,
    SUM(COALESCE(wra.web_return_cnt, 0)) AS web_return_cnt,
    (SUM(sr.sr_return_amt) - COALESCE(SUM(wra.web_return_amt), 0)) AS net_return_diff,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(sr.sr_return_amt) DESC) AS brand_rank
FROM store_returns sr
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_ret_agg wra
    ON sr.sr_item_sk = wra.wr_item_sk
WHERE i.i_wholesale_cost BETWEEN 0.5 AND 10
  AND s.s_market_id IN (3, 4, 5, 6, 10)
  AND s.s_tax_percentage >= 0.03
  AND ca.ca_country = 'United States'
  AND hd.hd_vehicle_count >= 1
  AND sr.sr_return_tax > 1
GROUP BY
    i.i_brand,
    i.i_category,
    s.s_store_name,
    ca.ca_state,
    hd.hd_buy_potential
HAVING SUM(sr.sr_return_amt) > 500
ORDER BY store_return_total DESC
LIMIT 100
