WITH returns_with_item_store AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        s.s_floor_space,
        s.s_market_desc
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE
        i.i_current_price BETWEEN 10 AND 500
        AND s.s_floor_space > 8000000
        AND s.s_market_desc LIKE '%Financial%'
        AND sr.sr_return_tax BETWEEN 2 AND 10
        AND sr.sr_return_quantity >= 2
        AND sr.sr_return_amt > 100
)
SELECT
    r.s_store_name,
    r.s_market_desc,
    r.i_category,
    r.i_brand,
    SUM(r.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    RANK() OVER (ORDER BY SUM(r.sr_return_amt) DESC) AS store_return_rank,
    ROW_NUMBER() OVER (PARTITION BY r.i_category ORDER BY SUM(r.sr_return_amt) DESC) AS category_store_rownum
FROM returns_with_item_store r
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca
    WHERE ca.ca_address_sk = r.sr_addr_sk
      AND ca.ca_gmt_offset = -6.00
      AND ca.ca_state = 'CA'
)
GROUP BY
    r.s_store_name,
    r.s_market_desc,
    r.i_category,
    r.i_brand
ORDER BY total_return_amount DESC
LIMIT 100
