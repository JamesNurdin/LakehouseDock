WITH filtered_pages AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_url,
        -- Extract the top‑level domain (e.g., com, org) from the URL
        regexp_extract(wp.wp_url, '\\.([a-z]{2,})$', 1) AS tld,
        -- Keep only pages whose type starts with 'shop' and whose URL contains '.com'
        CASE WHEN regexp_like(wp.wp_url, '^https?://.*\\.com') THEN 1 ELSE 0 END AS is_com_url
    FROM
        web_page wp
    WHERE
        wp.wp_type LIKE 'shop%'
        AND wp.wp_autogen_flag = 'N'
),
joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_bill_cdemo_sk,
        ws.ws_web_page_sk,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        fp.tld,
        fp.is_com_url
    FROM
        web_sales ws
        INNER JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        INNER JOIN filtered_pages fp
            ON ws.ws_web_page_sk = fp.wp_web_page_sk
    WHERE
        fp.is_com_url = 1
        AND cd.cd_purchase_estimate BETWEEN 1000 AND 5000
)
SELECT
    cd_gender,
    tld,
    COUNT(DISTINCT ws_order_number) AS orders_cnt,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_net_paid) AS avg_net_paid,
    -- Concatenate gender and tld for a readable label
    concat(cd_gender, '-', tld) AS gender_tld_label
FROM
    joined_data
GROUP BY
    cd_gender,
    tld,
    concat(cd_gender, '-', tld)
ORDER BY
    total_net_paid DESC
LIMIT 100
