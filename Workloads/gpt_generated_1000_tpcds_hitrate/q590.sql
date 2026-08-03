SELECT
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    wp.wp_url,
    wp.wp_link_count
FROM
    customer AS c
JOIN
    web_page AS wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    wp.wp_autogen_flag = 'Y'
    AND wp.wp_link_count > 10
    AND c.c_first_name = 'Amy'
