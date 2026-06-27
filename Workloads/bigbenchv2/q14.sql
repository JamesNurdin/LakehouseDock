WITH logs AS (
    SELECT
        TRY_CAST(NULLIF(element_at(split(line, '|'), 1), '') AS bigint)   AS wl_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint)   AS wl_customer_id,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 3), '') AS bigint)   AS wl_item_id,
        NULLIF(element_at(split(line, '|'), 4), '')                       AS wl_webpage_name,
        TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) AS wl_timestamp
    FROM iceberg.bigbenchv2_sf1.web_logs
    WHERE TRY_CAST(NULLIF(element_at(split(line, '|'), 2), '') AS bigint) IS NOT NULL
)
SELECT
    purchase_year,
    AVG(items_per_user) AS avg_items_per_user
FROM (
    SELECT
        wl_customer_id                AS userid,
        YEAR(purchase_ts)             AS purchase_year,
        cart_items                    AS items_per_user
    FROM logs
    MATCH_RECOGNIZE (
        PARTITION BY wl_customer_id
        ORDER BY wl_timestamp
        MEASURES
            (COUNT(*) - 1)            AS cart_items,
            LAST(B.wl_timestamp)      AS purchase_ts
        ONE ROW PER MATCH
        PATTERN (A+ B)
        DEFINE
            A AS wl_webpage_name IN (
                'webpage#01','webpage#02','webpage#03','webpage#04','webpage#05',
                'webpage#06','webpage#07','webpage#08','webpage#09','webpage#10',
                'webpage#11','webpage#12','webpage#13','webpage#14','webpage#15',
                'webpage#16','webpage#17','webpage#18','webpage#19','webpage#20'
            ),
            B AS wl_webpage_name IN (
                'webpage#21','webpage#22','webpage#23','webpage#24','webpage#25'
            )
    )
) t
GROUP BY purchase_year
ORDER BY purchase_year
