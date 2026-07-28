WITH inv_date AS (
    SELECT
        i.inv_date_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        d.d_date AS inv_date,
        d.d_year
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    it.i_brand,
    st.s_state,
    cc.cc_mkt_class,
    ws.web_country,
    SUM(iv.inv_quantity_on_hand) AS total_quantity,
    COUNT(DISTINCT iv.inv_item_sk) AS distinct_items,
    AVG(it.i_current_price) AS avg_current_price,
    MIN(iv.inv_date) AS first_inventory_date,
    MAX(iv.inv_date) AS last_inventory_date
FROM inv_date iv
JOIN item it ON iv.inv_item_sk = it.i_item_sk
JOIN store st ON iv.inv_date_sk = st.s_closed_date_sk
JOIN call_center cc ON iv.inv_date_sk = cc.cc_closed_date_sk
JOIN web_site ws ON iv.inv_date_sk = ws.web_open_date_sk
WHERE
    it.i_brand = 'Brand#12'
    AND st.s_state = 'CA'
    AND cc.cc_mkt_class = 'Associated'
    AND ws.web_country = 'United States'
    AND iv.inv_quantity_on_hand > 100
GROUP BY
    it.i_brand,
    st.s_state,
    cc.cc_mkt_class,
    ws.web_country
ORDER BY total_quantity DESC
LIMIT 100
