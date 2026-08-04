WITH sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        c.c_customer_id,
        SUM(cs.cs_net_profit) AS total_profit,
        split(cc.cc_name, ' ') AS name_words
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(cc.cc_name, '^.*Center$')
      AND ca.ca_city LIKE 'San%'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        c.c_customer_id
),

ranked AS (
    SELECT
        cc_call_center_id,
        cc_name,
        c_customer_id,
        total_profit,
        row_number() OVER (PARTITION BY cc_call_center_id ORDER BY total_profit DESC) AS rn,
        name_words
    FROM sales
),

top_customers AS (
    SELECT *
    FROM ranked
    WHERE rn <= 3
)

SELECT
    tc.cc_call_center_id,
    tc.cc_name,
    tc.c_customer_id,
    tc.total_profit,
    t.word,
    COUNT(*) OVER (PARTITION BY tc.cc_call_center_id, t.word) AS word_occurrences
FROM top_customers tc
CROSS JOIN UNNEST(split(tc.cc_name, ' ')) AS t(word)
WHERE regexp_extract(t.word, '([A-Z][a-z]+)', 1) IS NOT NULL
GROUP BY
    tc.cc_call_center_id,
    tc.cc_name,
    tc.c_customer_id,
    tc.total_profit,
    t.word
HAVING SUM(tc.total_profit) > 1000
ORDER BY tc.total_profit DESC, t.word
LIMIT 100
