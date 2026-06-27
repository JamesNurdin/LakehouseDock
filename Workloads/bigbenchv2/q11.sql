SELECT corr(reviews_count, avg_rating) AS correlation
FROM (
    SELECT
        p.pr_item_id AS pid,
        p.reviews_count,
        p.avg_rating,
        s.revenue AS m_revenue
    FROM (
        SELECT
            pr_item_id,
            COUNT(*) AS reviews_count,
            AVG(pr_rating) AS avg_rating
        FROM iceberg.bigbenchv2_sf1.product_reviews
        WHERE pr_item_id IS NOT NULL
        GROUP BY pr_item_id
    ) p
    JOIN (
        SELECT
            ws.ws_item_id,
            SUM(ws.ws_quantity * i.i_price) AS revenue
        FROM iceberg.bigbenchv2_sf1.web_sales ws
        JOIN iceberg.bigbenchv2_sf1.items i
          ON ws.ws_item_id = i.i_item_id
        WHERE ws.ws_item_id IS NOT NULL
          AND CAST(TRY_CAST(ws.ws_ts AS timestamp) AS date) >= DATE '2013-11-02'
          AND CAST(TRY_CAST(ws.ws_ts AS timestamp) AS date) <= DATE '2013-12-02'
        GROUP BY ws.ws_item_id
    ) s
      ON p.pr_item_id = s.ws_item_id
) q11_review_stats