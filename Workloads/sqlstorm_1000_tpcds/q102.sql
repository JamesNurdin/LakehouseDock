WITH date_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Store' AS sales_channel,
        s.s_store_sk AS location_sk,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_net_profit) AS total_net_profit,
        count(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        row_number() OVER (PARTITION BY d.d_year ORDER BY sum(ss.ss_net_paid) DESC) AS yearly_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_net_paid > 0
    GROUP BY d.d_year, d.d_month_seq, s.s_store_sk
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Catalog' AS sales_channel,
        c.cc_call_center_sk AS location_sk,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(DISTINCT cs.cs_order_number) AS distinct_orders,
        row_number() OVER (PARTITION BY d.d_year ORDER BY sum(cs.cs_net_paid) DESC) AS yearly_rank
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
    WHERE cs.cs_net_paid > 0
    GROUP BY d.d_year, d.d_month_seq, c.cc_call_center_sk
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Web' AS sales_channel,
        w.wp_web_page_sk AS location_sk,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_net_profit) AS total_net_profit,
        count(DISTINCT ws.ws_order_number) AS distinct_orders,
        row_number() OVER (PARTITION BY d.d_year ORDER BY sum(ws.ws_net_paid) DESC) AS yearly_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page w ON ws.ws_web_page_sk = w.wp_web_page_sk
    WHERE ws.ws_net_paid > 0
    GROUP BY d.d_year, d.d_month_seq, w.wp_web_page_sk
),
combined AS (
    SELECT * FROM date_sales
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
top_locations AS (
    SELECT
        sales_channel,
        location_sk,
        d_year,
        total_net_paid,
        total_net_profit,
        yearly_rank,
        CASE
            WHEN total_net_paid > 1000000 THEN 'High'
            WHEN total_net_paid > 500000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_volume_bucket,
        COALESCE(
            (SELECT c.cc_name FROM call_center c WHERE c.cc_call_center_sk = location_sk AND sales_channel = 'Catalog'),
            (SELECT s.s_store_name FROM store s WHERE s.s_store_sk = location_sk AND sales_channel = 'Store'),
            (SELECT wp.wp_url FROM web_page wp WHERE wp.wp_web_page_sk = location_sk AND sales_channel = 'Web')
        ) AS location_name
    FROM combined
    WHERE yearly_rank <= 10
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        sum(CASE WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_net_paid ELSE 0 END) AS total_cs_paid,
        sum(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS total_ws_paid,
        sum(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_net_paid ELSE 0 END) AS total_ss_paid,
        sum(
            CASE
                WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_net_profit
                WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_net_profit
                WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_net_profit
                ELSE 0
            END
        ) AS total_profit,
        row_number() OVER (
            PARTITION BY cd.cd_gender
            ORDER BY sum(
                CASE
                    WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_net_paid
                    WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_net_paid
                    WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_net_paid
                    ELSE 0
                END
            ) DESC
        ) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk
),
return_analysis AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Store' AS return_channel,
        sum(sr.sr_net_loss) AS total_net_loss,
        count(*) AS total_returns,
        avg(sr.sr_return_quantity) AS avg_quantity,
        sum(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        sum(COALESCE(sr.sr_fee, 0)) AS total_fee
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'Catalog' AS return_channel,
        sum(cr.cr_net_loss) AS total_net_loss,
        count(*) AS total_returns,
        avg(cr.cr_return_quantity) AS avg_quantity,
        sum(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        sum(COALESCE(cr.cr_fee, 0)) AS total_fee
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'Web' AS return_channel,
        sum(wr.wr_net_loss) AS total_net_loss,
        count(*) AS total_returns,
        avg(wr.wr_return_quantity) AS avg_quantity,
        sum(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        sum(COALESCE(wr.wr_fee, 0)) AS total_fee
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
final_report AS (
    SELECT
        tl.sales_channel,
        tl.sales_volume_bucket,
        tl.location_name,
        tl.total_net_paid,
        tl.total_net_profit,
        tl.yearly_rank,
        cs.full_name,
        cs.cd_gender,
        cs.hd_income_band_sk,
        cs.total_cs_paid,
        cs.total_ws_paid,
        cs.total_ss_paid,
        cs.total_profit,
        cs.gender_rank,
        ra.return_channel,
        ra.total_net_loss,
        ra.total_returns,
        ra.avg_quantity,
        ra.total_return_amount,
        ra.total_fee,
        CASE
            WHEN tl.sales_channel = ra.return_channel THEN 'Match'
            ELSE 'Mismatch'
        END AS channel_match_flag
    FROM top_locations tl
    LEFT JOIN customer_stats cs
        ON cs.gender_rank = tl.yearly_rank
        AND cs.total_profit > 0
    LEFT JOIN return_analysis ra
        ON ra.d_year = tl.d_year
        AND ra.return_channel = tl.sales_channel
    WHERE tl.sales_volume_bucket IS NOT NULL
)
SELECT *
FROM final_report
ORDER BY sales_channel, yearly_rank, total_net_paid DESC
LIMIT 100
