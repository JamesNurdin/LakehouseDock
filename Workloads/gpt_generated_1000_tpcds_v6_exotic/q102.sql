SELECT
    i.i_brand,
    i.i_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_cnt
FROM
    tpcds.store_returns AS sr
JOIN
    tpcds.item AS i
      ON sr.sr_item_sk = i.i_item_sk
WHERE
    sr.sr_fee > 30.00
    AND i.i_class = 'pants'
GROUP BY
    i.i_brand,
    i.i_category
ORDER BY
    distinct_ticket_cnt DESC
LIMIT 10
