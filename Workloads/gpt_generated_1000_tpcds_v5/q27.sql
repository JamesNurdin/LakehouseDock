WITH a AS (
    SELECT wp.wp_type,
           SUM(ws.ws_net_profit) AS profit_a
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_wholesale_cost > 60
      AND wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY wp.wp_type
),

b AS (
    SELECT wp.wp_type,
           SUM(ws.ws_net_profit) AS profit_b
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_ext_tax > 100
      AND wp.wp_type = 'home'
    GROUP BY wp.wp_type
)
SELECT DISTINCT type,
                profit
FROM (
        SELECT a.wp_type AS type,
               a.profit_a AS profit
        FROM a
        UNION ALL
        SELECT b.wp_type AS type,
               b.profit_b AS profit
        FROM b
     ) combined
ORDER BY profit DESC
LIMIT 100
