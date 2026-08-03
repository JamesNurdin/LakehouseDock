WITH
    inv_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_item_sk
    ),
    promo_agg AS (
        SELECT p_item_sk,
               COUNT(*) AS promo_cnt,
               SUM(p_cost) AS total_promo_cost
        FROM promotion
        WHERE p_cost > 10
        GROUP BY p_item_sk
    ),
    joined AS (
        SELECT
            sr.sr_store_sk,
            s.s_store_name,
            s.s_state,
            sr.sr_item_sk,
            i.i_product_name,
            i.i_current_price,
            ca.ca_state AS cust_state,
            inv_agg.total_qty,
            promo_agg.promo_cnt,
            sr.sr_return_amt,
            sr.sr_fee,
            CASE
                WHEN sr.sr_return_amt > 100 THEN 'High'
                WHEN sr.sr_return_amt > 0   THEN 'Medium'
                ELSE 'Low'
            END AS return_level
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
        LEFT JOIN promo_agg ON i.i_item_sk = promo_agg.p_item_sk
        WHERE sr.sr_return_quantity > 0
          AND sr.sr_fee >= 15
          AND i.i_current_price BETWEEN 5 AND 500
          AND s.s_gmt_offset BETWEEN -5 AND 5
    ),
    store_agg AS (
        SELECT
            sr_store_sk,
            s_store_name,
            SUM(sr_return_amt) AS store_total_return,
            AVG(sr_fee) AS avg_fee,
            COUNT(*) AS return_cnt,
            SUM(CASE WHEN return_level = 'High' THEN 1 ELSE 0 END) AS high_return_cnt
        FROM joined
        GROUP BY sr_store_sk, s_store_name
        HAVING SUM(sr_return_amt) > 1000
    ),
    low_returns AS (
        SELECT
            sr_store_sk,
            s_store_name,
            SUM(sr_return_amt) AS store_total_return
        FROM joined
        GROUP BY sr_store_sk, s_store_name
        HAVING SUM(sr_return_amt) < 500
    )
SELECT *
FROM (
    SELECT sr_store_sk,
           s_store_name,
           store_total_return,
           avg_fee,
           return_cnt,
           high_return_cnt
    FROM store_agg
    EXCEPT
    SELECT sr_store_sk,
           s_store_name,
           store_total_return,
           CAST(NULL AS double) AS avg_fee,
           CAST(NULL AS integer) AS return_cnt,
           CAST(NULL AS integer) AS high_return_cnt
    FROM low_returns
) diff
WHERE sr_store_sk NOT IN (SELECT sr_store_sk FROM low_returns)
ORDER BY store_total_return DESC
LIMIT 100
