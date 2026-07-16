WITH store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        s.s_state AS region_state,
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        CAST(0.00 AS decimal(7,2)) AS return_amount,
        CAST(0.00 AS decimal(7,2)) AS net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        s.s_state AS region_state,
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        CAST(0.00 AS decimal(7,2)) AS net_paid,
        CAST(0.00 AS decimal(7,2)) AS net_profit,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        cc.cc_state AS region_state,
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        CAST(0.00 AS decimal(7,2)) AS return_amount,
        CAST(0.00 AS decimal(7,2)) AS net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        cc.cc_state AS region_state,
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        CAST(0.00 AS decimal(7,2)) AS net_paid,
        CAST(0.00 AS decimal(7,2)) AS net_profit,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        w.web_state AS region_state,
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        CAST(0.00 AS decimal(7,2)) AS return_amount,
        CAST(0.00 AS decimal(7,2)) AS net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        ca.ca_state AS region_state,
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        CAST(0.00 AS decimal(7,2)) AS net_paid,
        CAST(0.00 AS decimal(7,2)) AS net_profit,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
agg AS (
    SELECT
        d_year,
        d_quarter_seq,
        region_state,
        i_category,
        i_class,
        i_brand,
        SUM(net_paid) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(return_amount) AS total_returns,
        SUM(net_loss) AS total_loss,
        SUM(net_paid) - SUM(return_amount) AS net_revenue,
        SUM(net_profit) - SUM(net_loss) AS net_gain
    FROM combined
    GROUP BY ROLLUP (d_year, d_quarter_seq, region_state, i_category, i_class, i_brand)
),
ranked AS (
    SELECT
        d_year,
        d_quarter_seq,
        region_state,
        i_category,
        i_class,
        i_brand,
        total_sales,
        total_profit,
        total_returns,
        total_loss,
        net_revenue,
        net_gain,
        ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY net_gain DESC) AS rank_by_gain
    FROM agg
    WHERE d_year IS NOT NULL
)
SELECT
    d_year,
    d_quarter_seq,
    region_state,
    i_category,
    i_class,
    i_brand,
    total_sales,
    total_profit,
    total_returns,
    total_loss,
    net_revenue,
    net_gain,
    rank_by_gain
FROM ranked
WHERE rank_by_gain <= 10
ORDER BY d_year, i_category, rank_by_gain
